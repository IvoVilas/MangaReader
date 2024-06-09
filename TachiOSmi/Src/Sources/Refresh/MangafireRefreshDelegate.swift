//
//  MangafireRefreshDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation

final class MangafireRefreshDelegate: RefreshDelegateType {

  private let httpClient: HttpClientType
  private let parser: MangafireParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangafireParser()
  }

  func fetchRefreshData(
    _ mangaId: String,
    updateCover: Bool
  ) async throws -> MangaRefreshData {
    let url = "https://mangafire.to/manga/\(mangaId)"
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://mangafire.to/home")

    let details = try parser.parseMangaDetailsResponse(html, mangaId: mangaId)
    let chapters = try parser.parseChaptersResponse(html, mangaId: mangaId)
    let cover = updateCover ? try? await fetchCover(mangaId: mangaId, coverInfo: details.coverInfo) : nil

    return MangaRefreshData(
      id: mangaId,
      cover: cover,
      details: details,
      chapters: chapters
    )
  }

}

extension MangafireRefreshDelegate {

  private func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    try await httpClient.makeDataSafeGetRequest(
      coverInfo, 
      comingFrom: "https://mangafire.to/",
      addRefererCookies: true
    )
  }

}
