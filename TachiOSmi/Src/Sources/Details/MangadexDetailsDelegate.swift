//
//  MangadexDetailsDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

final class MangadexDetailsDelegate: DetailsDelegateType {

  private let httpClient: HttpClientType
  private let mangaParser: MangaParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.mangaParser = MangaParser()
  }

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaDetailsParsedData {
    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga/\(mangaId)",
      parameters: [
        ("includes[]", "author"),
        ("includes[]", "cover_art")
      ]
    )

    guard let data = json["data"] as? [String: Any] else {
      throw ParserError.parameterNotFound("data")
    }

    return try mangaParser.parseMangaDetailsResponse(data)
  }

  func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(mangaId)/\(coverInfo).256.jpg"
    )
  }

}
