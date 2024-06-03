//
//  MangafireDetailsDeletage.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 03/06/2024.
//

import Foundation
import SwiftSoup

final class MangafireDetailsDeletage: DetailsDelegateType {

  static private let defaultCoverUrl = "https://mangafire.to/assets/sites/mangafire/logo.png?v3"

  private let httpClient: HttpClientType

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
  }

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaDetailsParsedData {
    let url = "https://mangafire.to/manga/\(mangaId)"
    let html = try await httpClient.makeHtmlGetRequest(url)

    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let container = try? doc.select("div.manga-detail").select("div.container"),
      let sidebar = try? container.select("aside.sidebar"),
      let content = try? container.select("aside.content"),
      let info = try? content.select("div.info")
    else {
      throw ParserError.parsingError
    }

    let title = try? info.select("h1").text()
    let status = try? info.select("p").text()
    let description = try? doc.select("div.modal.fade#synopsis").select("div.modal-content.p-4").text()
    let coverUrl = try? container.select("div.poster").select("img").attr("src")

    let meta = try? sidebar.select("div.meta")
    let authors = try? meta?.select("a[itemprop=author]").array().compactMap { element -> (String, String)? in
      let name = try? element.text()
      let url = try? element.attr("href")
      let id = url?.components(separatedBy: "/").last

      if let id, let name { return (id, name) }

      return nil
    }.map { AuthorModel(id: $0.0, name: $0.1) }

    let tags = try? meta?.select("div:has(span:contains(Genres:))").select("span:contains(Genres:) + span a[href]").array().compactMap { element -> (String, String)? in
      let title = try? element.text()
      let url = try? element.attr("href")
      let id = url?.components(separatedBy: "/").last

      if let id, let title { return (id, title) }

      return nil
    }.map { TagModel(id: $0.0, title: $0.1) }

    return MangaDetailsParsedData(
      id: mangaId,
      title: title ?? "Unknown title",
      description: description,
      status: parseStatus(status ?? "unknown"),
      tags: tags ?? [],
      authors: authors ?? [],
      coverInfo: coverUrl ?? MangafireDetailsDeletage.defaultCoverUrl
    )
  }

  func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    try await httpClient.makeDataGetRequest(url: coverInfo)
  }

}

extension MangafireDetailsDeletage {

  private func parseStatus(_ value: String) -> MangaStatus {
    switch value.lowercased() {
    case "releasing":
      return .ongoing

    case "completed":
      return .completed

    case "on_hiatus", "discontinued":
      return .hiatus

    default:
      return .unknown
    }
  }

}
