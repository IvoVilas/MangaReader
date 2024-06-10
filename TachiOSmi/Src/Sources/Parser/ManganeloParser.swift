//
//  ManganeloParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation
import SwiftSoup

struct ManganeloParser {

  static private let defaultCoverUrl = "https://chapmanganelo.com/themes/hm/images/404_not_found.png"

  private let dateFormatter: DateFormatter

  init() {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "MMM dd,yyyy HH:mm"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    self.dateFormatter = dateFormatter
  }

}

// MARK: Search Parser
extension ManganeloParser {

  func parseMangaTrendingResponse(
    _ html: String
  ) throws -> [MangaSearchResultParsedData] {
    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let elements = try? doc.select("div.content-genres-item")
    else {
      throw ParserError.parsingError
    }

    return elements.compactMap { element -> MangaSearchResultParsedData? in
      guard
        let url = try? element.select("a[data-id]").attr("href"),
        let idComponent = url.components(separatedBy: "/").last,
        let id = idComponent.components(separatedBy: "-").last
      else {
        print("ManganeloSearchDelegate -> Parameter id not found")

        return nil
      }

      guard let title = try? element.select("h3 a").text() else {
        print("ManganeloSearchDelegate -> Parameter title not found")

        return nil
      }

      guard let url = try? element.select("img.img-loading").attr("src") else {
        print("ManganeloSearchDelegate -> Parameter cover not found")

        return nil
      }

      return MangaSearchResultParsedData(
        id: id,
        title: title,
        coverDownloadInfo: url
      )
    }
  }

  func parseMangaSearchResponse(
    _ html: String
  ) throws -> [MangaSearchResultParsedData] {
    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let elements = try? doc.select("div.search-story-item")
    else {
      throw ParserError.parsingError
    }

    return elements.compactMap { element -> MangaSearchResultParsedData? in
      guard
        let url = try? element.select("a[data-id]").attr("href"),
        let idComponent = url.components(separatedBy: "/").last,
        let id = idComponent.components(separatedBy: "-").last
      else {
        print("ManganeloSearchDelegate -> Parameter id not found")

        return nil
      }

      let finalId: String
      if url.hasPrefix("https://m.manganelo.com/") {
        finalId = "\(id)%1"
      } else {
        finalId = "\(id)%0"
      }

      guard let title = try? element.select("h3 a").text() else {
        print("ManganeloSearchDelegate -> Parameter title not found")

        return nil
      }

      guard let url = try? element.select("img.img-loading").attr("src") else {
        print("ManganeloSearchDelegate -> Parameter cover not found")

        return nil
      }

      return MangaSearchResultParsedData(
        id: finalId,
        title: title,
        coverDownloadInfo: url
      )
    }
  }

}

// MARK: Details Parser
extension ManganeloParser {

  func parseDetailsResponse(
    _ html: String,
    mangaId: String
  ) throws -> MangaDetailsParsedData {
    guard
      let doc: Document = try? SwiftSoup.parse(html),
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
      coverInfo: cover ?? ManganeloParser.defaultCoverUrl
    )
  }

}

// MARK: Chapter Parser
extension ManganeloParser {

  func parseChaptersResponse(
    _ html: String,
    mangaId: String
  ) throws -> [ChapterIndexResult] {
    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let chapterListInfo = try? doc.select("div.panel-story-chapter-list").first(),
      let chaptersInfo = try? chapterListInfo.select("li.a-h").array()
    else {
      throw ParserError.parsingError
    }

    // The id retrived here does not seem to be unique
    // So the chapter Id is {mangaId}%{chapterId}
    // Futhrmore we cant get the number of pages
    // So we use 1 to go throught the numberOfPages > 0 filter later on
    return chaptersInfo.compactMap { element -> ChapterIndexResult? in
      guard
        let id = try? element.attr("id"),
        let info = try? element.select("a.chapter-name").first,
        let url = try? info.attr("href")
      else {
        return nil
      }

      var number: Double?
      var date: Date?
      let title = try? info.attr("title")

      if let numberString = url.components(separatedBy: "-").last {
        number = Double(numberString)
      }

      if let dateString = try? element.select("span.chapter-time").attr("title") {
        date = dateFormatter.date(from: dateString)
      }

      return ChapterIndexResult(
        id: "\(mangaId)%\(id)",
        title: title,
        number: number,
        numberOfPages: 1, // TODO: Do something about this
        publishAt: date ?? Date.distantPast, // TODO: And this
        downloadInfo: url
      )
    }
  }

}
