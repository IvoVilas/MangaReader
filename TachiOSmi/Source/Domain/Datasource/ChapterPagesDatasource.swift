//
//  ChapterPagesDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import Foundation
import Combine

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
      self.pages.value.append(contentsOf: pages)
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

    await MainActor.run { currentPage += 1 }

    let results = await withTaskGroup(of: PageModel.self, returning: [PageModel].self) { taskGroup in
      for (index, data) in pagedData.enumerated() {
        taskGroup.addTask {
          do {
            let pageData = try await self.httpClient.makeDataGetRequest(url: "\(chapterPages.url)/\(data)")

            return .remote(offset + index, pageData)
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

}
