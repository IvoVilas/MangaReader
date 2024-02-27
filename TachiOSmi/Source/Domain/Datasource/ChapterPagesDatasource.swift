//
//  ChapterPagesDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import Foundation
import Combine
import UIKit

final class ChapterPagesDatasource {

  private let chapter: ChapterModel
  private let httpClient: HttpClient

  private let pages: CurrentValueSubject<[PageModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var pagesPublisher: AnyPublisher<[PageModel], Never> {
    pages
      .map { $0.sorted { $0.rawId < $1.rawId } }
      .eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  @MainActor private var currentPage = 0
  @MainActor private var chapterPages: ChapterPagesModel?

  init(
    chapter: ChapterModel,
    httpClient: HttpClient
  ) {
    self.chapter    = chapter
    self.httpClient = httpClient

    pages = CurrentValueSubject([])
    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  // TODO: Falta colocar loading temporario enquanto páginas não carregam
  func refresh() async {
    await MainActor.run {
      self.currentPage = 0
      self.pages.value = []
      self.state.value = .loading
    }

    var erro: DatasourceError?
    var pages = [PageModel]()

    do {
      let chapterPages = try await getChapterPages()

      pages = try await makePagesRequest(using: chapterPages)
    } catch let error as ParserError {
      erro = .errorParsingResponse(error.localizedDescription)
    } catch let error as HttpError {
      erro = .networkError(error.localizedDescription)
    } catch let error as CrudError {
      erro = .databaseError(error.localizedDescription)
    } catch {
      erro = .unexpectedError(error.localizedDescription)
    }

    await MainActor.run { [pages, erro] in
      self.state.value = .normal
      self.error.value = erro
      self.pages.value = pages
    }
  }

  func loadNextPages() async {
    var erro: DatasourceError?
    var pages = [PageModel]()

    do {
      let chapterPages = try await getChapterPages()

      pages = try await makePagesRequest(using: chapterPages)

      if pages.isEmpty {
        return
      }
    } catch let error as ParserError {
      erro = .errorParsingResponse(error.localizedDescription)
    } catch let error as HttpError {
      erro = .networkError(error.localizedDescription)
    } catch let error as CrudError {
      erro = .databaseError(error.localizedDescription)
    } catch {
      erro = .unexpectedError(error.localizedDescription)
    }

    await MainActor.run { [pages, erro] in
      self.error.value = erro
      self.updateOrAppend(pages)
    }
  }

  private func getChapterPages() async throws -> ChapterPagesModel {
    if let local = await chapterPages {
      return local
    }

    let remote = try await makeChapterPagesRequest()

    await MainActor.run { chapterPages = remote }

    return remote
  }

  private func updateOrAppend(
    _ pages: [PageModel]
  ) {
    var oldPages = self.pages.value

    for page in pages {
      if let i = oldPages.firstIndex(where: { $0.id == page.id }) {
        oldPages[i] = page
      } else {
        oldPages.append(page)
      }
    }

    self.pages.value = oldPages
  }

}

extension ChapterPagesDatasource {

  private func makeChapterPagesRequest() async throws -> ChapterPagesModel {
    print("MangaReaderViewModel -> Starting chapter page download info")

    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/at-home/server/\(chapter.id)"
    )

    guard
      let baseUrl = json["baseUrl"] as? String,
      let chapterJson = json["chapter"] as? [String: Any],
      let hash = chapterJson["hash"] as? String,
      let dataArray = chapterJson["data"] as? [String]
    else {
      throw ParserError.parsingError
    }

    print("MangaReaderViewModel -> Ended chapter page download info")

    return ChapterPagesModel(
      baseUrl: baseUrl,
      hash: hash,
      data: dataArray
    )
  }

  private func makePagesRequest(
    using chapterPages: ChapterPagesModel
  ) async throws -> [PageModel] {
    print("MangaReaderViewModel -> Starting chapter download")

    let limit     = 10
    let offset    = await limit * currentPage
    let dataArray = chapterPages.data

    if offset >= dataArray.count {
      return []
    }

    let endIndex  = min(dataArray.count, offset + limit)
    let pagedData = dataArray[offset ..< endIndex]

    await MainActor.run {
      currentPage += 1
      self.pages.value.append(
        contentsOf: pagedData.indices.map { .loading($0) }
      )
    }

    let results = await withTaskGroup(of: PageModel.self, returning: [PageModel].self) { taskGroup in
      for (index, data) in pagedData.enumerated() {
        taskGroup.addTask {
          do {
            let pageData = try await self.httpClient.makeDataGetRequest(url: "\(chapterPages.url)/\(data)")

            if let flippedData = self.flipData(pageData) {
              return .remote(offset + index, flippedData)
            } else {
              print("MangaReaderViewModel -> Failed to flip page data")

              return .notFound(offset + index)
            }
          } catch {
            print("MangaReaderViewModel -> Page \(offset + index) failed download: \(error)")

            return .notFound(offset + index)
          }
        }
      }

      return await taskGroup.reduce(into: [PageModel]()) { partialResult, page in
        partialResult.append(page)
      }
    }

    print("MangaReaderViewModel -> Ending chapter download")

    return results
  }

  // TODO: There has to be a better way to do this
  // Context: Using LazyHStack with right to left layout direction does not work
  // For some reason, the stack is drawn showing the last page instead of the first
  // The biggest nail since the crucifixion of Jesus Christ:
  // On the view side we mirror the view when using rightToLeftLayout
  // Here we also flip the data horizontally
  // That way the LazyHStack is drawn correctly and the pages are also
  private func flipData(_ data: Data) -> Data? {
    guard let image = UIImage(data: data) else { return nil }

    if let imageCG = image.cgImage {
      let width  = imageCG.width
      let height = imageCG.height
      let bitsPerComponent = imageCG.bitsPerComponent
      let bytesPerRow = imageCG.bytesPerRow

      if 
        let space = imageCG.colorSpace,
        let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: space,
        bitmapInfo: imageCG.bitmapInfo.rawValue
      ) {
        context.translateBy(x: CGFloat(width), y: 0)
        context.scaleBy(x: -1.0, y: 1.0)

        context.draw(imageCG, in: CGRect(x: 0, y: 0, width: width, height: height))

        if let flippedImage = context.makeImage() {
          return UIImage(cgImage: flippedImage).jpegData(compressionQuality: 1)
        }
      }
    }

    return nil
  }

}
