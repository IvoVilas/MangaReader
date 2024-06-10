//
//  MangadexSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation

final class MangadexSearchDelegate: SearchDelegateType {

  let searchPageSize = 15
  let trendingPageSize = 15

  private let httpClient: HttpClientType
  private let parser: MangadexParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangadexParser()
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
    let offset = page * searchPageSize

    let results = try await makeSearchRequest(
      searchValue,
      limit: searchPageSize,
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
        ("offset", offset),
        ("contentRating[]", "safe"),
        ("contentRating[]", "suggestive"),
        ("contentRating[]", "erotica")
        //("contentRating[]", "pornographic")
      ]
    )

    guard let dataJson = data["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    return try parser.parseMangaSearchResponse(dataJson)
  }

}
