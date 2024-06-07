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
  private let parser: MangafireParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangafireParser()
  }

  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterIndexResult] {
    let url = "https://mangafire.to/manga/\(mangaId)"
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://mangafire.to/home")

    return try parser.parseChaptersResponse(html, mangaId: mangaId)
  }

}
