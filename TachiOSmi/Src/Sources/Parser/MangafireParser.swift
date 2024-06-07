//
//  MangafireParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation
import SwiftSoup

struct MangafireParser {

  static private let defaultCoverUrl = "https://mangafire.to/assets/sites/mangafire/logo.png?v3"

  private let dateFormatter: DateFormatter

  init() {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "MMMM dd, yyyy"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    self.dateFormatter = dateFormatter
  }

}

// MARK: Search Parser
extension MangafireParser {

  func parseMangaSearchResponse(
    _ html: String
  ) throws -> [MangaSearchResultParsedData] {
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

}

// MARK: Details Parser
extension MangafireParser {

  func parseMangaDetailsResponse(
    _ html: String,
    mangaId: String
  ) throws -> MangaDetailsParsedData {
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
      coverInfo: coverUrl ?? MangafireParser.defaultCoverUrl
    )
  }

}

// MARK: Chapters Parser
extension MangafireParser {

  func parseChaptersResponse(
    _ html: String,
    mangaId: String
  ) throws -> [ChapterIndexResult] {
    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let items = try? doc.select("ul.scroll-sm > li.item"),
      let trueId = mangaId.components(separatedBy: ".").last
    else {
      throw ParserError.parsingError
    }

    // The id retrived here does not seem to be unique
    // So the chapter Id is {mangaId}%{chapterId}
    // Futhrmore we cant get the number of pages
    // So we use 1 to go throught the numberOfPages > 0 filter later on
    return items.compactMap { item -> ChapterIndexResult? in
      guard
        let a = try? item.select("a[href]"),
        let url = try? a.attr("href"),
        let id = url.components(separatedBy: "/").last
      else {
        return nil
      }

      var number: Double?
      var date: Date?
      let title = try? a.select("span").first()?.text()

      if let numberString = try? item.attr("data-number") {
        number = Double(numberString)
      }

      if let dateString = try? a.select("span").last()?.text() {
        date = parseDate(from: dateString)
      }

      return ChapterIndexResult(
        id: "\(mangaId)%\(id)",
        title: title,
        number: number,
        numberOfPages: 1, // TODO: Do something about this
        publishAt: date ?? Date.distantPast, // TODO: And this
        downloadInfo: "\(url)%\(trueId)"
      )
    }
  }

}

// MARK: Helpers
extension MangafireParser {

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

  private func parseDate(from value: String) -> Date? {
    let systemDateTime = AppEnv.env.systemDateTime

    if let date = dateFormatter.date(from: value) {
      return date
    }

    guard let regex = try? NSRegularExpression(pattern: #"(\d+) hours? ago"#) else {
      return nil
    }

    let range = NSRange(value.startIndex..<value.endIndex, in: value)

    guard
      let match = regex.firstMatch(in: value, range: range),
      let timeRange = Range(match.range(at: 1), in: value),
      let timeSince = Int(String(value[timeRange]))
    else {
      return nil
    }

    return systemDateTime.calculator.removeHours(timeSince, to: systemDateTime.now)
  }

}

