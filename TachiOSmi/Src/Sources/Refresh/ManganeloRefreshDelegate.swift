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
    let url = mangaId
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://www.nelomanga.com/")

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
    let referer = "https://www.nelomanga.com/"

    return try await httpClient.makeDataSafeGetRequest(
      coverInfo,
      comingFrom: referer,
      addRefererCookies: true
    )
  }

}
