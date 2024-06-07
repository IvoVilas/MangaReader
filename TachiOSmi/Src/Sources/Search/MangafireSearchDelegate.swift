//
//  MangafireSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 02/06/2024.
//

import Foundation

final class MangafireSearchDelegate: SearchDelegateType {

  private let httpClient: HttpClientType
  private let parser: MangafireParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangafireParser()
  }

  func fetchTrending(
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let url = "https://mangafire.to/filter?&sort=trending&page=\(page + 1)"
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://google.com")

    return try parser.parseMangaSearchResponse(html)
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

      url = "https://mangafire.to/filter?keyword=\(noSpecialChars)&sort=trending&page=\(page + 1)"
    } else {
      url = "https://mangafire.to/filter?&sort=trending&page=\(page + 1)"
    }

    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://google.com")

    return try parser.parseMangaSearchResponse(html)
  }

  func fetchCover(
    mangaId: String,
    coverInfo url: String
  ) async throws -> Data {
    try await httpClient.makeDataGetRequest(url: url)
  }

}
