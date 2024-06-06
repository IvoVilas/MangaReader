//
//  MangafireChaptersDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 03/06/2024.
//

import Foundation
import SwiftSoup

final class MangafireChaptersDelegate: ChaptersDelegateType {

  private let httpClient: HttpClientType
  private let dateFormatter: DateFormatter

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "MMMM dd, yyyy"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
  }

  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterIndexResult] {
    let url = "https://mangafire.to/manga/\(mangaId)"
    let html = try await httpClient.makeHtmlGetRequest(url)

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

extension MangafireChaptersDelegate {

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
