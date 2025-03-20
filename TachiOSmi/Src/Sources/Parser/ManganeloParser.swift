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

    dateFormatter.dateFormat = "MMM-dd-yyyy HH:mm"
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
      let panel = try? doc.select("div.panel_story_list").first(),
      let elements = try? panel.select("div.story_item").array()
    else {
      throw ParserError.parsingError
    }

    return elements.compactMap { element -> MangaSearchResultParsedData? in
      guard
        let titleElement = try? element.select(".story_name a").first(),
        let title = try? titleElement.text(),
        let url = try? titleElement.attr("href"),
        let cover = try? element.select("a img").first()?.attr("src")
      else {
        return nil
      }

      return MangaSearchResultParsedData(
        id: url,
        title: title,
        coverDownloadInfo: cover
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
      let leftCol = try? doc.select("div.leftCol").first(),
      let mangaInfoTop = try? leftCol.select("div.manga-info-top").first(),
      let mangaInfoPic = try? mangaInfoTop.select("div.manga-info-pic").first(),
      let mangaInfoText = try? mangaInfoTop.select("ul.manga-info-text").first()
    else {
      throw ParserError.parsingError
    }

    let title = try? mangaInfoText.select("h1").text()
    let cover = try? mangaInfoPic.select("img").first()?.attr("src")
    let description = try? leftCol.select("#contentBox").first()?.ownText()
    let status = try? mangaInfoText.select("li:contains(Status)").text().replacingOccurrences(of: "Status : ", with: "")

    let authors = try? mangaInfoText.select("li:contains(Author) a").array().compactMap { element -> (String, String)? in
      let name = try? element.text()
      let url = try? element.attr("href")
      let id = url?.components(separatedBy: "/").last

      if let id, let name { return (id, name) }

      return nil
    }.map { AuthorModel(id: $0.0, name: $0.1) }

    let tags = try? mangaInfoText.select("li.genres a").array().compactMap { element -> (String, String)? in
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
      let leftCol = try? doc.select("div.leftCol").first(),
      let chapterRows = try? leftCol.select(".chapter-list .row").array()
    else {
      throw ParserError.parsingError
    }

    // The id retrived here does not seem to be unique
    // So the chapter Id is {mangaId}%{chapterId}
    // Futhrmore we cant get the number of pages
    // So we use 1 to go throught the numberOfPages > 0 filter later on
    return chapterRows.compactMap { element -> ChapterIndexResult? in
      guard
        let chapterElement = try? element.select("span a").first(),
        let url = try? chapterElement.attr("href")
      else {
        return nil
      }

      var number: Double?
      var date: Date?
      let title = try? chapterElement.text()

      if let numberString = title?.replacingOccurrences(of: "Chapter ", with: "") {
        number = Double(numberString)
      }

      if let dateString = try? element.select("span").last()?.attr("title") {
        date = dateFormatter.date(from: dateString)
      }

      return ChapterIndexResult(
        id: url,
        title: title,
        number: number,
        numberOfPages: 1, // TODO: Do something about this
        publishAt: date ?? Date.distantPast, // TODO: And this
        downloadInfo: url
      )
    }
  }

}
