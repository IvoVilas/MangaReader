//
//  MangadexSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation

final class MangadexSearchDelegate: SearchDelegateType {

  private let httpClient: HttpClient
  private let mangaParser: MangaParser

  init(
    httpClient: HttpClient
  ) {
    self.httpClient = httpClient
    self.mangaParser = MangaParser()
  }
  
  func fetchTrending(
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    try await fetchSearchResults("", page: page)
  }

  func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let limit  = 15
    let offset = page * limit

    let results = try await makeSearchRequest(
      searchValue,
      limit: limit,
      offset: offset
    )

    return results
  }

  func fetchCover(
    mangaId: String,
    coverInfo filename: String
  ) async throws -> Data {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(mangaId)/\(filename).256.jpg"
    )
  }

}

extension MangadexSearchDelegate {

  private func makeSearchRequest(
    _ searchValue: String,
    limit: Int,
    offset: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let data: [String: Any] = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga",
      parameters: [
        ("title", searchValue),
        ("order[followedCount]", "desc"),
        ("order[relevance]", "desc"),
        ("includes[]", "cover_art"),
        ("includes[]", "author"),
        ("limit", limit),
        ("offset", offset)
      ]
    )

    guard let dataJson = data["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    return try mangaParser.parseMangaSearchResponse(dataJson)
  }

}
