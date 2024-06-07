//
//  ManganeloChaptersDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

final class ManganeloChaptersDelegate: ChaptersDelegateType {

  private let httpClient: HttpClientType
  private let parser: ManganeloParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = ManganeloParser()
  }

  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterIndexResult] {
    let url = "https://chapmanganelo.com/manga-\(mangaId)"
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://m.manganelo.com/wwww")

    return try parser.parseChaptersResponse(html, mangaId: mangaId)
  }

}
