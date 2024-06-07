//
//  MangafirePagesDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 03/06/2024.
//

import Foundation
import SwiftSoup

final class MangafirePagesDelegate: PagesDelegateType {

  private let httpClient: HttpClientType

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
  }

  func fetchDownloadInfo(
    using info: String,
    saveData: Bool
  ) async throws -> ChapterDownloadInfo {
    let components = info.components(separatedBy: "%")
    
    guard
      components.count == 2,
      let url = components.first,
      let mangaId = components.last
    else {
      throw ParserError.parsingError
    }

    let chapterId = try await getChapterId(url: url, mangaId: mangaId)

    let response = try await httpClient.makeJsonSafeGetRequest(
      url: "https://mangafire.to/ajax/read/chapter/\(chapterId)",
      comingFrom: "https://mangafire.to\(url)",
      parameters: []
    )

    guard
      let result = response["result"] as? [String: Any],
      let images = result["images"] as? [[Any]]
    else {
      throw ParserError.parsingError
    }

    let pages = images.compactMap {
      if let page = $0.first as? String {
        return page
      } else {
        print("MangafirePagesDelegate -> Failed to parse a page")

        return nil
      }
    }

    return ChapterDownloadInfo(
      downloadUrl: url,
      pages: pages
    )
  }

  func fetchPage(
    index: Int,
    info: ChapterDownloadInfo
  ) async throws -> Data {
    guard info.pages.indices.contains(index) else { throw DatasourceError.unexpectedError("Page index out of bounds") }

    let components = info.downloadUrl.components(separatedBy: "%")

    guard let url = components.first else {
      throw ParserError.parsingError
    }

    return try await httpClient.makeDataSafeGetRequest(
      info.pages[index],
      comingFrom: "https://mangafire.to\(url)"
    )
  }

  func fetchPage(
    url: String,
    info: ChapterDownloadInfo
  ) async throws -> Data {
    return try await httpClient.makeDataSafeGetRequest(
      url,
      comingFrom: info.downloadUrl
    )
  }

  func buildPageUrl(
    index: Int,
    info: ChapterDownloadInfo
  ) throws -> String {
    let pages = info.pages

    guard pages.indices.contains(index) else { throw DatasourceError.otherError("Page index out of bounds") }

    return pages[index]
  }

}

extension MangafirePagesDelegate {

  private func getChapterId(
    url: String,
    mangaId: String
  ) async throws -> String {
    let html = try await httpClient.makeHtmlSafeGetRequest(
      "https://mangafire.to/ajax/read/\(mangaId)/chapter/en",
      comingFrom: "https://mangafire.to\(url)"
    )

    let formattedUrl = "\"\(url)\""
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "/", with: "\\/")

    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let link = try? doc.select("a[href=\(formattedUrl)]"),
      let chapterId = try? link.attr("data-id")
    else {
      throw ParserError.parsingError
    }

    return chapterId
      .replacingOccurrences(of: "\"", with: "")
      .replacingOccurrences(of: "\\", with: "")
  }

}
