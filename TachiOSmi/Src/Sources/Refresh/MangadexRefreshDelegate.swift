//
//  MangadexRefreshDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation

final class MangadexRefreshDelegate: RefreshDelegateType {

  private let httpClient: HttpClientType
  private let parser: MangadexParser

  init(
    httpClient: HttpClientType
  ) {
    self.httpClient = httpClient
    self.parser = MangadexParser()
  }
  
  func fetchRefreshData(
    _ mangaId: String,
    updateCover: Bool
  ) async throws -> MangaRefreshData {
    let details = try await fetchDetails(mangaId)

    async let chapters = try await fetchChapters(mangaId: mangaId)

    if updateCover {
      print("True")
      async let cover = try? await fetchCover(mangaId: mangaId, coverInfo: details.coverInfo)

      return await MangaRefreshData(
        id: mangaId,
        cover: cover,
        details: details,
        chapters: try chapters
      )
    }

    print("False")
    return await MangaRefreshData(
      id: mangaId,
      cover: nil,
      details: details,
      chapters: try chapters
    )
  }

}

extension MangadexRefreshDelegate {

  private func fetchDetails(
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

    return try parser.parseMangaDetailsResponse(data)
  }

  private func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(mangaId)/\(coverInfo).256.jpg"
    )
  }

  private func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterIndexResult] {
    var results = [ChapterIndexResult]()
    let limit   = 25
    var offset  = 0

    while true {
      let result = try await makeChapterFeedRequest(
        mangaId: mangaId,
        limit: limit,
        offset: offset
      )

      if result.isEmpty { break }

      offset += limit

      results.append(contentsOf: result)
    }

    return results
  }

  private func makeChapterFeedRequest(
    mangaId: String,
    limit: Int,
    offset: Int
  ) async throws -> [ChapterIndexResult] {
    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga/\(mangaId)/feed",
      parameters: [
        ("translatedLanguage[]", "en"),
        ("order[chapter]", "desc"),
        ("order[createdAt]", "desc"),
        ("limit", limit),
        ("offset", offset)
      ]
    )

    guard let dataJson = json["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    return try parser
      .parseChapterData(mangaId: mangaId, data: dataJson)
      .filter { $0.numberOfPages > 0 }
  }

}
