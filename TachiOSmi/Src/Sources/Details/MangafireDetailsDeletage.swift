//
//  MangafireDetailsDeletage.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 03/06/2024.
//

import Foundation

final class MangafireDetailsDeletage: DetailsDelegateType {

  private let httpClient: HttpClientType
  private let parser: MangafireParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangafireParser()
  }

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaDetailsParsedData {
    let url = "https://mangafire.to/manga/\(mangaId)"
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://mangafire.to/home")

    return try parser.parseMangaDetailsResponse(html, mangaId: mangaId)
  }

  func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    try await httpClient.makeDataSafeGetRequest(coverInfo, comingFrom: "https://mangafire.to/manga/\(mangaId)")
  }

}
