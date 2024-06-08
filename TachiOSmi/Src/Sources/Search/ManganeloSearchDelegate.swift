//
//  ManganeloSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

final class ManganeloSearchDelegate: SearchDelegateType {

  private let httpClient: HttpClientType
  private let parser: ManganeloParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = ManganeloParser()
  }

  func fetchTrending(
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let url = "https://m.manganelo.com/genre-all/\(page + 1)?type=topview"
    let html = try await httpClient.makeHtmlGetRequest(url)

    return try parser.parseMangaTrendingResponse(html)
  }

  func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let url: String
    var set = CharacterSet.alphanumerics
    set.insert("_")

    if !searchValue.isEmpty {
      let noSpaces = searchValue.lowercased().replacingOccurrences(of: " ", with: "_")
      let noSpecialChars = String(noSpaces.unicodeScalars.filter(set.contains))
      url = "https://m.manganelo.com/search/story/\(noSpecialChars)?page=\(page + 1)"
    } else {
      url = "https://m.manganelo.com/genre-all?type=topview"
    }

    let html = try await httpClient.makeHtmlGetRequest(url)

    return try parser.parseMangaSearchResponse(html)
  }
  
  func fetchCover(
    mangaId: String,
    coverInfo url: String
  ) async throws -> Data {
    try await httpClient.makeDataGetRequest(url: url)
  }

}
