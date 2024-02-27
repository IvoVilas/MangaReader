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
    pages.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  private var observers = Set<AnyCancellable>()

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

  func refresh() async {
    pages.value = (0..<chapter.numberOfPages).map { .loading($0) }
    state.value = .loading

    do {
      try await makePagesRequest()
    } catch let error as ParserError {
      self.error.value = .errorParsingResponse(error.localizedDescription)
    } catch let error as HttpError {
      self.error.value = .networkError(error.localizedDescription)
    } catch let error as CrudError {
      self.error.value = .databaseError(error.localizedDescription)
    } catch {
      self.error.value = .unexpectedError(error.localizedDescription)
    }

    state.value = .normal
  }

  private func makePagesRequest() async throws {
    print("MangaReaderViewModel -> Starting chapter download")

    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/at-home/server/\(chapter.id)"
    )

    guard
      let baseUrl = json["baseUrl"] as? String,
      let chapterJson = json["chapter"] as? [String: Any],
      let hash = chapterJson["hash"] as? String,
      let dataArray = chapterJson["data"] as? [String]
    else {
      pages.value = []

      throw ParserError.parsingError
    }

    if dataArray.count != pages.value.count {
      print("MangaReaderViewModel -> Number of pages did not match expected")

      pages.value = (0..<dataArray.count).map { .loading($0) }
    }

    _ = await withTaskGroup(of: Void.self) { taskGroup in
      for (index, data) in dataArray.enumerated() {
        taskGroup.addTask {
          do {
            let data = try await self.httpClient.makeDataGetRequest(url: "\(baseUrl)/data/\(hash)/\(data)")

            await MainActor.run {
              self.pages.value[index] = .remote(index, data)
            }
          } catch {
            await MainActor.run {
              self.pages.value[index] = .notFound(index)
            }
          }
        }

        await taskGroup.waitForAll()
      }
    }

    print("MangaReaderViewModel -> Ending chapter download")
  }

}
