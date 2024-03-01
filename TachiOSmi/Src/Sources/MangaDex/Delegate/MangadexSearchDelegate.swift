//
//  MangadexSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

final class MangadexSearchDelegate: SearchDelegateType {

  private let httpClient: HttpClient
  private let mangaParser: MangaParser

  init(
    httpClient: HttpClient,
    mangaParser: MangaParser
  ) {
    self.httpClient = httpClient
    self.mangaParser = mangaParser
  }
  
  func fetchTrending(
    page: Int
  ) async throws -> [MangaParsedData] {
    try await fetchSearchResults("", page: page)
  }

  func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaParsedData] {
    let limit  = 15
    let offset = page * limit

    let results = try await makeSearchRequest(
      searchValue,
      limit: limit,
      offset: offset
    )

    return results
  }

  func fetchCover(
    id: String,
    fileName: String
  ) async throws -> Data {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(id)/\(fileName).256.jpg"
    )
  }

  func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      print("MangaSearchDelegate -> Task cancelled")

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as CrudError:
      print("MangaSearchDelegate -> Error during database operation: \(error.localizedDescription)")

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
  }

}

extension MangadexSearchDelegate {

  private func makeSearchRequest(
    _ searchValue: String,
    limit: Int,
    offset: Int
  ) async throws -> [MangaParsedData] {
    let data: [String: Any] = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga",
      parameters: [
        ("title", searchValue),
        ("order[followedCount]", "desc"),
        ("order[relevance]", "desc"),
        ("includes[]", "cover_art"),
        ("includes[]", "author"),
        ("limit", limit),
        ("offset", offset)
      ]
    )

    guard let dataJson = data["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    return try mangaParser.parseMangaSearchResponse(dataJson)
  }

}
