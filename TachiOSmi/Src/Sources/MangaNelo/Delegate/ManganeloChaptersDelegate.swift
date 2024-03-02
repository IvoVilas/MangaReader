//
//  ManganeloChaptersDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import SwiftSoup

final class ManganeloChaptersDelegate: ChaptersDelegateType {

  private let httpClient: HttpClient
  private let dateFormatter: DateFormatter

  init(
    httpClient: HttpClient,
    chapterParser: ChapterParser
  ) {
    self.httpClient = httpClient
    self.dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "MMM dd,yyyy HH:mm"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
  }

  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterModel] {
    let url = "https://chapmanganelo.com/manga-\(mangaId)"
    let html = try await httpClient.makeHtmlGetRequest(url)

    guard let doc: Document = try? SwiftSoup.parse(html) else {
      throw ParserError.parsingError
    }

    guard
      let chapterListInfo = try? doc.select("div.panel-story-chapter-list").first(),
      let chaptersInfo = try? chapterListInfo.select("li.a-h").array()
    else {
      throw ParserError.parsingError
    }

    // The id retrived here does not seem to be unique
    // So the chapter Id is {mangaId}%{chapterId}
    // Futhrmore we cant get the number of pages
    // So we use 1 to go throught the numberOfPages > 0 filter later on
    return chaptersInfo.compactMap { element -> ChapterModel? in
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

      return ChapterModel(
        id: "\(mangaId)%\(id)",
        title: title,
        number: number,
        numberOfPages: 1, // TODO: Do something about this
        publishAt: date ?? Date.distantPast, // TODO: And this
        urlInfo: url
      )
    }
  }

}
