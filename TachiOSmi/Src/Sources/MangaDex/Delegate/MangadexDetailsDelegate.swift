//
//  MangadexDetailsDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

final class MangadexDetailsDelegate: DetailsDelegateType {

  private let httpClient: HttpClient
  private let mangaParser: MangaParser

  init(
    httpClient: HttpClient,
    mangaParser: MangaParser
  ) {
    self.httpClient = httpClient
    self.mangaParser = mangaParser
  }

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaParsedData {
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

    return try mangaParser.parseMangaIndexResponse(data)
  }

  func fetchCover(
    mangaId: String,
    fileName: String
  ) async throws -> Data {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(mangaId)/\(fileName).256.jpg"
    )
  }

  func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      print("MangaDetailsDelegate -> Task cancelled")

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as CrudError:
      print("MangaDetailsDelegate -> Error during database operation: \(error.localizedDescription)")

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
  }

}
