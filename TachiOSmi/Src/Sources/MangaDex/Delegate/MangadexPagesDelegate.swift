//
//  MangadexPagesDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation

final class MangadexPagesDelegate: PagesDelegateType {

  private let httpClient: HttpClient

  init(
    httpClient: HttpClient
  ) {
    self.httpClient = httpClient
  }

  func fetchDownloadInfo(
    using chapterId: String
  ) async throws -> ChapterDownloadInfo {
    return try await makeChapterInfoRequest(chapterId: chapterId)
  }
  
  func fetchPage(
    index: Int,
    info: ChapterDownloadInfo
  ) async throws -> Data {
    let url = try buildPageUrl(
      index: index,
      info: info
    )

    return try await makePageRequest(url)
  }

  func fetchPage(
    _ url: String
  ) async throws -> Data {
    return try await makePageRequest(url)
  }

  func buildPageUrl(
    index: Int,
    info: ChapterDownloadInfo
  ) throws -> String {
    let pages = info.pages

    guard pages.indices.contains(index) else { throw DatasourceError.otherError("Page index out of bounds") }

    let page = pages[index]

    return "\(info.downloadUrl)/\(page)"
  }

}


extension MangadexPagesDelegate {

  private func makeChapterInfoRequest(
    chapterId: String
  ) async throws -> ChapterDownloadInfo {
    print("MangaReaderViewModel -> Starting chapter page download info")

    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/at-home/server/\(chapterId)"
    )

    guard
      let baseUrl = json["baseUrl"] as? String,
      let chapterJson = json["chapter"] as? [String: Any],
      let hash = chapterJson["hash"] as? String,
      let pages = chapterJson["data"] as? [String]
    else {
      throw ParserError.parsingError
    }

    print("MangaReaderViewModel -> Ended chapter page download info")

    return ChapterDownloadInfo(
      downloadUrl: "\(baseUrl)/data/\(hash)",
      pages: pages
    )
  }

  func makePageRequest(
    _ url: String
  ) async throws -> Data {
    let data = try await httpClient.makeDataGetRequest(url: url)

    return data
  }

}
