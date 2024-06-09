//
//  ManganeloRefreshDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation

final class ManganeloRefreshDelegate: RefreshDelegateType {

  private let httpClient: HttpClientType
  private let parser: ManganeloParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = ManganeloParser()
  }

  func fetchRefreshData(
    _ mangaId: String,
    updateCover: Bool
  ) async throws -> MangaRefreshData {
    let url = "https://chapmanganelo.com/manga-\(mangaId)"
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://m.manganelo.com/")

    let details = try parser.parseDetailsResponse(html, mangaId: mangaId)
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

extension ManganeloRefreshDelegate {

  private func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    try await httpClient.makeDataSafeGetRequest(
      coverInfo,
      comingFrom: "https://chapmanganelo.com/",
      addRefererCookies: false
    )
  }

}
