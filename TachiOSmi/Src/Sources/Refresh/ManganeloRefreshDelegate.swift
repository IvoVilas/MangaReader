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
    let components = mangaId.components(separatedBy: "%")

    guard let id = components.first else {
      throw ParserError.parameterNotFound("Id")
    }

    let url: String
    if let urlType = components.safeGet(1), urlType == "1" {
      url = "https://m.manganelo.com/manga-\(id)"
    } else {
      url = "https://chapmanganelo.com/manga-\(id)"
    }

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
    let referer: String
    if let urlType = mangaId.components(separatedBy: "%").safeGet(1), urlType == "1" {
      referer = "https://m.manganelo.com/"
    } else {
      referer = "https://chapmanganelo.com/"
    }

    return try await httpClient.makeDataSafeGetRequest(
      coverInfo,
      comingFrom: referer,
      addRefererCookies: false
    )
  }

}
