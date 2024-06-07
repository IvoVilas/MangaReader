//
//  MangadexChaptersDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

final class MangadexChaptersDelegate: ChaptersDelegateType {

  private let httpClient: HttpClientType
  private let parser: MangadexParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangadexParser()
  }
  
  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterIndexResult] {
    var results = [ChapterIndexResult]()
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

}

extension MangadexChaptersDelegate {

  private func makeChapterFeedRequest(
    mangaId: String,
    limit: Int,
    offset: Int
  ) async throws -> [ChapterIndexResult] {
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

    return try parser
      .parseChapterData(mangaId: mangaId, data: dataJson)
      .filter { $0.numberOfPages > 0 }
  }

}
