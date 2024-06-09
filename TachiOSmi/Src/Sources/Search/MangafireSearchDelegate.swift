//
//  MangafireSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 02/06/2024.
//

import Foundation

final class MangafireSearchDelegate: SearchDelegateType {

  let searchPageSize = 30
  let trendingPageSize = 30

  private let httpClient: HttpClientType
  private let parser: MangafireParser

  private var lastRequest: String?

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangafireParser()
  }

  func fetchTrending(
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let (url, referer) = getTrendingUrlAndReferer(page: page)
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: referer)

    lastRequest = url

    return try parser.parseMangaSearchResponse(html)
  }

  func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let (url, referer) = getSearchUrlAndReferer(search: searchValue, page: page)
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: referer)

    lastRequest = url

    return try parser.parseMangaSearchResponse(html)
  }

  func fetchCover(
    mangaId: String,
    coverInfo url: String
  ) async throws -> Data {
    try await httpClient.makeDataSafeGetRequest(
      url,
      comingFrom: "https://mangafire.to/",
      addRefererCookies: true
    )
  }

}

extension MangafireSearchDelegate {

  private func getTrendingUrlAndReferer(
    page: Int
  ) -> (String, String) {
    let url: String
    let referer: String

    if page == 0 {
      url = "https://mangafire.to/trending"
      referer = lastRequest ?? "https://www.google.com/"
    } else if page == 1 {
      url = "https://mangafire.to/trending?page=\(page + 1)"
      referer = lastRequest ?? "https://mangafire.to/trending"
    } else {
      url = "https://m.manganelo.com/genre-all/\(page + 1)?type=topview"
      referer = lastRequest ?? "https://mangafire.to/trending?page=\(page)"
    }

    return (url, referer)
  }

  private func getSearchUrlAndReferer(
    search: String,
    page: Int
  ) -> (String, String) {
    guard !search.isEmpty else {
      return getTrendingUrlAndReferer(page: page)
    }

    let url: String
    let referer: String
    var set = CharacterSet.alphanumerics
    set.insert("_")

    let noSpaces = search.lowercased().replacingOccurrences(of: " ", with: "+")
    let noSpecialChars = String(noSpaces.unicodeScalars.filter(set.contains))

    if page == 0 {
      url = "https://mangafire.to/filter?keyword=\(noSpecialChars)&sort=trending"
      referer = lastRequest ?? "https://mangafire.to/home"
    } else if page == 1 {
      url = "https://mangafire.to/filter?keyword=\(noSpecialChars)&sort=trending&page=\(page + 1)"
      referer = lastRequest ?? "https://mangafire.to/filter?keyword=\(noSpecialChars)&sort=trending"
    } else {
      url = "https://m.manganelo.com/search/story/\(noSpecialChars)?page=\(page + 1)"
      referer = lastRequest ?? "https://m.manganelo.com/search/story/\(noSpecialChars)?page=\(page)"
    }

    return (url, referer)
  }

}
