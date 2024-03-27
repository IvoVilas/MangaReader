//
//  ManganeloDetailsDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import SwiftSoup

final class ManganeloDetailsDelegate: DetailsDelegateType {

  static private let defaultCoverUrl = "https://chapmanganelo.com/themes/hm/images/404_not_found.png"

  private let httpClient: HttpClient

  init(
    httpClient: HttpClient
  ) {
    self.httpClient = httpClient
  }

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaDetailsParsedData {
    let url = "https://chapmanganelo.com/manga-\(mangaId)"
    let html = try await httpClient.makeHtmlGetRequest(url)

    guard let doc: Document = try? SwiftSoup.parse(html) else {
      throw ParserError.parsingError
    }

    guard
      let panelStoryInfo = try? doc.select("div.panel-story-info").first(),
      let leftPanelInfo = try? panelStoryInfo.select("div.story-info-left").first(),
      let rightPanelInfo = try? panelStoryInfo.select("div.story-info-right").first(),
      let variationsTableInfo = try? rightPanelInfo.select("table.variations-tableInfo").first()
    else {
      throw ParserError.parsingError
    }

    let title = try? rightPanelInfo.select("h1").text()
    let cover = try? leftPanelInfo.select("span.info-image img.img-loading").attr("src")
    let description = try? panelStoryInfo.select("div.panel-story-info-description").text()
    let status = try? variationsTableInfo.select("td.table-label:has(i.info-status) + td.table-value").text()

    let authors = try? variationsTableInfo.select("td.table-label:has(i.info-author) + td.table-value a.a-h").array().compactMap { element -> (String, String)? in
      let name = try? element.text()
      let url = try? element.attr("href")
      let id = url?.components(separatedBy: "/").last

      if let id, let name { return (id, name) }

      return nil
    }.map { AuthorModel(id: $0.0, name: $0.1) }

    let tags = try? variationsTableInfo.select("td.table-label:has(i.info-genres) + td.table-value a.a-h").array().compactMap { element -> (String, String)? in
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
      status: .safeInit(from: status ?? "unkown"),
      tags: tags ?? [],
      authors: authors ?? [],
      coverInfo: cover ?? ManganeloDetailsDelegate.defaultCoverUrl
    )
  }
  
  func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    try await httpClient.makeDataGetRequest(url: coverInfo)
  }
  
}
