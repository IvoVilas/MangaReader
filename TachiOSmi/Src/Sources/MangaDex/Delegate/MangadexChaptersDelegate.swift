//
//  MangadexChaptersDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

final class MangadexChaptersDelegate: ChaptersDelegateType {

  private let httpClient: HttpClient
  private let chapterParser: ChapterParser

  init(
    httpClient: HttpClient,
    chapterParser: ChapterParser
  ) {
    self.httpClient = httpClient
    self.chapterParser = chapterParser
  }
  
  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterModel] {
    var results = [ChapterModel]()
    let limit   = 25
    var offset  = 0

    while true {
      try Task.checkCancellation()

      let result = try await makeChapterFeedRequest(
        mangaId: mangaId,
        limit: limit,
        offset: offset
      )

      if result.isEmpty { break }

      offset += limit

      results.append(contentsOf: result)
    }

    return results
  }

  func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      print("MangaChapterDelegate -> Task cancelled")

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as CrudError:
      print("MangaChapterDelegate -> Error during database operation: \(error.localizedDescription)")

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
  }

}

extension MangadexChaptersDelegate {

  private func makeChapterFeedRequest(
    mangaId: String,
    limit: Int,
    offset: Int
  ) async throws -> [ChapterModel] {
    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga/\(mangaId)/feed",
      parameters: [
        ("translatedLanguage[]", "en"),
        ("order[chapter]", "desc"),
        ("order[createdAt]", "desc"),
        ("limit", limit),
        ("offset", offset)
      ]
    )

    guard let dataJson = json["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    return chapterParser
      .parseChapterData(mangaId: mangaId, data: dataJson)
      .filter { $0.numberOfPages > 0 }
  }

}
