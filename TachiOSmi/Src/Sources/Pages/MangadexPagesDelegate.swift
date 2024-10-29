//
//  MangadexPagesDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation

final class MangadexPagesDelegate: PagesDelegateType {

  private let httpClient: HttpClientType

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
  }

  func fetchDownloadInfo(
    mangaId: String,
    using chapterId: String,
    saveData: Bool
  ) async throws -> ChapterDownloadInfo {
    return try await makeChapterInfoRequest(
      chapterId: chapterId,
      saveData: saveData
    )
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
    url: String
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
    chapterId: String,
    saveData: Bool
  ) async throws -> ChapterDownloadInfo {
    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/at-home/server/\(chapterId)",
      parameters: []
    )

    guard
      let baseUrl = json["baseUrl"] as? String,
      let chapterJson = json["chapter"] as? [String: Any],
      let hash = chapterJson["hash"] as? String,
      let pages = chapterJson[saveData ? "dataSaver" : "data"] as? [String]
    else {
      throw ParserError.parsingError
    }

    return ChapterDownloadInfo(
      downloadUrl: "\(baseUrl)/\(saveData ? "data-saver" : "data")/\(hash)",
      pages: pages
    )
  }

  private func makePageRequest(
    _ url: String
  ) async throws -> Data {
    let data = try await httpClient.makeDataGetRequest(url: url)

    return data
  }

}
