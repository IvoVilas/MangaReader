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

  @MainActor var hasMorePages = true
  @MainActor private var currentPage = 0
  @MainActor private var chapterInfo: ChapterDownloadInfoModel?

  init(
    chapter: ChapterModel,
    httpClient: HttpClient
  ) {
    self.chapter = chapter
    self.httpClient = httpClient

    pages = CurrentValueSubject([])
    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func refresh() async {
    await MainActor.run {
      self.currentPage = 0
      self.hasMorePages = true
      self.pages.valueOnMain = []
      self.state.valueOnMain = .loading
    }

    var erro: DatasourceError?
    var pages = [PageModel]()
    var hasMorePages = true

    do {
      let chapterInfo = try await getChapterInfo()

      pages = try await makePagesRequest(using: chapterInfo)

      if pages.isEmpty {
        hasMorePages = false

        throw DatasourceError.otherError("No pages found")
      }
    } catch {
      erro = catchError(error)
    }

    await MainActor.run { [pages, erro, hasMorePages] in
      self.error.valueOnMain = erro
      self.pages.valueOnMain = pages
      self.hasMorePages = hasMorePages
    }
  }

  func loadNextPages() async {
    var hasMorePages = await hasMorePages

    if !hasMorePages { return }

    var erro: DatasourceError?
    var pages = [PageModel]()

    do {
      let chapterInfo = try await getChapterInfo()

      pages = try await makePagesRequest(using: chapterInfo)

      if pages.isEmpty {
        hasMorePages = false
      }
    } catch {
      erro = catchError(error)
    }

    await MainActor.run { [pages, erro, hasMorePages] in
      self.error.valueOnMain = erro
      self.hasMorePages = hasMorePages
      
      self.updateOrAppend(pages)
    }
  }

  func reloadPages(
    _ pages: [(id: Int, url: String)]
  ) async {
    await self.tryToUpdatePages(pages.map { .loading($0.id) })

    await withTaskGroup(of: Void.self) { taskGroup in
      for info in pages {
        taskGroup.addTask {
          let id = info.id
          let url = info.url

          var erro: DatasourceError?
          let page: PageModel

          do {
            print("ChapterPagesDatasource -> Reloading page \(id)")
            let data = try await self.makePageRequest(url)

            page = .remote(id, data)
          } catch {
            erro = self.catchError(error)
            page = .notFound(id, url)
          }

          await MainActor.run { [page, erro] in
            self.error.valueOnMain = erro
            self.tryToUpdatePage(page)
          }

          print("ChapterPagesDatasource -> Ended page \(id) reload with error: \(String(describing: erro))")
        }
      }
    }
  }

  private func getChapterInfo() async throws -> ChapterDownloadInfoModel {
    if let local = await chapterInfo {
      return local
    }

    let remote = try await makeChapterInfoRequest()

    await MainActor.run { chapterInfo = remote }

    return remote
  }

  @MainActor
  private func tryToUpdatePages(
    _ pages: [PageModel]
  ) {
    pages.forEach { tryToUpdatePage($0) }
  }

  @MainActor
  private func tryToUpdatePage(
    _ page: PageModel
  ) {
    if let i = pages.valueOnMain.firstIndex(where: { $0.id == page.id }) {
      pages.valueOnMain[i] = page
    }
  }

  @MainActor
  private func updateOrAppend(
    _ info: [PageModel]
  ) {
    for page in info {
      if let i = pages.valueOnMain.firstIndex(where: { $0.id == page.id }) {
        pages.valueOnMain[i] = page
      } else {
        pages.valueOnMain.append(page)
      }
    }
  }

}

// MARK: Error
extension ChapterPagesDatasource {
  
  private func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      return .unexpectedError("Task was unexpectedly canceled")

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as CrudError:
      print("ChapterPagesDatasource -> Error during database operaiton: \(error)")

    case let error as DatasourceError:
      return error

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
  }

}

// MARK: Network
extension ChapterPagesDatasource {

  private func makeChapterInfoRequest() async throws -> ChapterDownloadInfoModel {
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

    return ChapterDownloadInfoModel(
      baseUrl: baseUrl,
      hash: hash,
      data: dataArray
    )
  }

  private func makePagesRequest(
    using chapterInfo: ChapterDownloadInfoModel
  ) async throws -> [PageModel] {
    print("MangaReaderViewModel -> Starting chapter download")
    let currentPage = await MainActor.run(resultType: Int.self) {
      let currentPage = self.currentPage

      self.currentPage += 1

      return currentPage
    }

    let limit     = 10
    let offset    = limit * currentPage
    let dataArray = chapterInfo.data

    if offset >= dataArray.count {
      return []
    }

    let endIndex  = min(dataArray.count, offset + limit)
    let pagedData = dataArray[offset ..< endIndex]

    await MainActor.run {
      self.pages.valueOnMain.append(
        contentsOf: pagedData.indices.map { .loading($0) }
      )
    }

    let results = await withTaskGroup(of: PageModel.self, returning: [PageModel].self) { taskGroup in
      for (index, data) in pagedData.enumerated() {
        taskGroup.addTask {
          let url = "\(chapterInfo.url)/\(data)"

          do {
            let data = try await self.makePageRequest(url)

            return .remote(offset + index, data)
          } catch {
            print("MangaReaderViewModel -> Page \(offset + index) failed download: \(error)")

            return .notFound(offset + index, url)
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

  private func makePageRequest(
    _ url: String
  ) async throws -> Data {
    var data = try await httpClient.makeDataGetRequest(url: url)
    data = try flipData(data)

    return data
  }

}

// MARK: Data manipulation
extension ChapterPagesDatasource {

  // TODO: There has to be a better way to do this
  // Context: Using LazyHStack with right to left layout direction does not work
  // For some reason, the stack is drawn showing the last page instead of the first
  // The biggest nail since the crucifixion of Jesus Christ:
  // On the view side we mirror the view when using rightToLeftLayout
  // Here we also flip the data horizontally
  // That way the LazyHStack is drawn correctly and the pages are also
  private func flipData(_ data: Data) throws -> Data {
    guard let image = UIImage(data: data) else { throw DatasourceError.unexpectedError("") }

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
          if let flippedData = UIImage(cgImage: flippedImage).jpegData(compressionQuality: 1) {
            return flippedData
          }
        }
      }
    }

    throw DatasourceError.unexpectedError("")
  }


}
