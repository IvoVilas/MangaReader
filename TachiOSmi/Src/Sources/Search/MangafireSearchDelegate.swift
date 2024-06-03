//
//  MangafireSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 02/06/2024.
//

import Foundation
import SwiftSoup

final class MangafireSearchDelegate: SearchDelegateType {

  private let httpClient: HttpClientType

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
  }

  func fetchTrending(
    page: Int
  ) async throws -> [MangaSearchResultParsedData] {
    let url = "https://mangafire.to/filter?&sort=trending&page=\(page + 1)"
    let html = try await httpClient.makeHtmlGetRequest(url)

    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let card = try? doc.select("div.original.card-lg").first(),
      let elements = try? card.select("div.unit")
    else {
      throw ParserError.parsingError
    }

    return elements.compactMap { element -> MangaSearchResultParsedData? in
      guard
        let inner = try? element.select("div.inner"),
        let poster = try? inner.select("a.poster"),
        let id = try? poster.attr("href").components(separatedBy: "/").last,
        let img = try? poster.select("img"),
        let title = try? img.attr("alt"),
        let coverUrl = try? img.attr("src")
      else {
        print("ManganeloSearchDelegate -> Entity parameters not found")

        return nil
      }

      return MangaSearchResultParsedData(
        id: id,
        title: title,
        coverDownloadInfo: coverUrl
      )
    }
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

    let html = try await httpClient.makeHtmlGetRequest(url)

    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let card = try? doc.select("div.original.card-lg").first(),
      let elements = try? card.select("div.unit")
    else {
      throw ParserError.parsingError
    }

    return elements.compactMap { element -> MangaSearchResultParsedData? in
      guard
        let inner = try? element.select("div.inner"),
        let poster = try? inner.select("a.poster"),
        let id = try? poster.attr("href").components(separatedBy: "/").last,
        let img = try? poster.select("img"),
        let title = try? img.attr("alt"),
        let coverUrl = try? img.attr("src")
      else {
        print("ManganeloSearchDelegate -> Entity parameters not found")

        return nil
      }

      return MangaSearchResultParsedData(
        id: id,
        title: title,
        coverDownloadInfo: coverUrl
      )
    }
  }

  func fetchCover(
    mangaId: String,
    coverInfo url: String
  ) async throws -> Data {
    try await httpClient.makeDataGetRequest(url: url)
  }

}
