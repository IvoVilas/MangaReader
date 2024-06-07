//
//  ManganeloDetailsDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import SwiftSoup

final class ManganeloDetailsDelegate: DetailsDelegateType {

  private let httpClient: HttpClientType
  private let parser: ManganeloParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = ManganeloParser()
  }

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaDetailsParsedData {
    let url = "https://chapmanganelo.com/manga-\(mangaId)"
    let html = try await httpClient.makeHtmlSafeGetRequest(url, comingFrom: "https://m.manganelo.com/wwww")

    return try parser.parseDetailsResponse(html, mangaId: mangaId)
  }
  
  func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    try await httpClient.makeDataGetRequest(url: coverInfo)
  }
  
}
