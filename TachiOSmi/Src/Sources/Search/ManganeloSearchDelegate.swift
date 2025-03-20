//
//  ManganeloSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

final class ManganeloSearchDelegate: SearchDelegateType {

  let searchPageSize = 20
  let trendingPageSize = 24

  private let httpClient: HttpClientType
  private let parser: ManganeloParser

  private var lastRequest: String?

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = ManganeloParser()
  }

  func fetchTrending(
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let (url, referer) = getTrendingUrlAndReferer(page: page)

    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: referer)

    lastRequest = url

    return try parser.parseMangaTrendingResponse(html)
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
      comingFrom: "https://www.nelomanga.com/",
      addRefererCookies: true
    )
  }

}

extension ManganeloSearchDelegate {

  private func getTrendingUrlAndReferer(
    page: Int
  ) -> (String, String) {
    let url: String
    let referer: String

    if page == 0 {
      url = "https://www.nelomanga.com/genre-all?type=topview"
      referer = lastRequest ?? "https://www.nelomanga.com"
    } else if page == 1 {
      url = "https://www.nelomanga.com/genre-all/\(page + 1)?type=topview"
      referer = lastRequest ?? "https://www.nelomanga.com/genre-all?type=topview"
    } else {
      url = "https://www.nelomanga.com/genre-all/\(page + 1)?type=topview"
      referer = lastRequest ?? "https://www.nelomanga.com/genre-all/\(page)?type=topview"
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

    let noSpaces = search.lowercased().replacingOccurrences(of: " ", with: "_")
    let noSpecialChars = String(noSpaces.unicodeScalars.filter(set.contains))
    
    if page == 0 {
      url = "https://www.nelomanga.com/search/story/\(noSpecialChars)"
      referer = lastRequest ?? "https://www.nelomanga.com/"
    } else if page == 1 {
      url = "https://www.nelomanga.com/search/story/\(noSpecialChars)?page=\(page + 1)"
      referer = lastRequest ?? "https://www.nelomanga.com/search/story/\(noSpecialChars)"
    } else {
      url = "https://www.nelomanga.com/search/story/\(noSpecialChars)?page=\(page + 1)"
      referer = lastRequest ?? "https://www.nelomanga.com/search/story/\(noSpecialChars)?page=\(page)"
    }

    return (url, referer)
  }

}
