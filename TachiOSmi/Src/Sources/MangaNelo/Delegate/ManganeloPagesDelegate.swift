//
//  ManganeloPagesDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import SwiftSoup

final class ManganeloPagesDelegate: PagesDelegateType {

  private let httpClient: HttpClient

  init(
    httpClient: HttpClient
  ) {
    self.httpClient = httpClient
  }

  func fetchDownloadInfo(
    using url: String
  ) async throws -> ManganeloChapterDownloadInfo {
    let html = try await httpClient.makeHtmlGetRequest(url)

    guard let doc: Document = try? SwiftSoup.parse(html) else {
      throw ParserError.parsingError
    }

    guard
      let info = try? doc.select("div.container-chapter-reader").first(),
      let pages = try? info.select("img.reader-content").array()
    else {
      throw ParserError.parsingError
    }

    return ManganeloChapterDownloadInfo(
      chapterUrl: url,
      pages: pages.compactMap { try? $0.attr("src") }
    )
  }

  func fetchPage(
    index: Int,
    info: ManganeloChapterDownloadInfo
  ) async throws -> Data {
    guard info.pages.indices.contains(index) else { throw DatasourceError.unexpectedError("Page index out of bounds") }

    return try await httpClient.makeDataSafeGetRequest(
      info.pages[index],
      hotLink: info.chapterUrl
    )
  }

  func buildUrl(
    index: Int,
    info: ManganeloChapterDownloadInfo
  ) throws -> String {
    let pages = info.pages

    guard pages.indices.contains(index) else { throw DatasourceError.otherError("Page index out of bounds") }

    return pages[index]
  }
  
}
