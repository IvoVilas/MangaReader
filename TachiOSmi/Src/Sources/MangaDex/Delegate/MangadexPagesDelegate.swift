//
//  MangadexPagesDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

final class MangadexPagesDelegate: PagesDelegateType {

  private let httpClient: HttpClient

  init(
    httpClient: HttpClient
  ) {
    self.httpClient = httpClient
  }

  func fetchDownloadInfo(
    chapterId: String
  ) async throws -> MangadexChapterDownloadInfo {
    return try await makeChapterInfoRequest(chapterId: chapterId)
  }
  
  func fetchPage(
    index: Int,
    info: MangadexChapterDownloadInfo
  ) async throws -> Data {
    let url = try buildUrl(
      index: index,
      info: info
    )

    return try await makePageRequest(url)
  }

  func fetchPage(
    _ url: String
  ) async throws -> Data {
    return try await makePageRequest(url)
  }

  func buildUrl(
    index: Int,
    info: MangadexChapterDownloadInfo
  ) throws -> String {
    let dataArray = info.data

    guard dataArray.indices.contains(index) else { throw DatasourceError.otherError("Page index out of bounds") }

    let data = dataArray[index]

    return "\(info.url)/\(data)"
  }

  func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      return .unexpectedError("Task was unexpectedly canceled")

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as CrudError:
      print("ChapterPagesDatasource -> Error during database operation: \(error)")

    case let error as DatasourceError:
      return error

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
  }

}


extension MangadexPagesDelegate {

  private func makeChapterInfoRequest(
    chapterId: String
  ) async throws -> MangadexChapterDownloadInfo {
    print("MangaReaderViewModel -> Starting chapter page download info")

    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/at-home/server/\(chapterId)"
    )

    guard
      let baseUrl = json["baseUrl"] as? String,
      let chapterJson = json["chapter"] as? [String: Any],
      let hash = chapterJson["hash"] as? String,
      let dataArray = chapterJson["data"] as? [String]
    else {
      throw ParserError.parsingError
    }

    print("MangaReaderViewModel -> Ended chapter page download info")

    return MangadexChapterDownloadInfo(
      baseUrl: baseUrl,
      hash: hash,
      data: dataArray
    )
  }

  func makePageRequest(
    _ url: String
  ) async throws -> Data {
    let data = try await httpClient.makeDataGetRequest(url: url)

    return data
  }

}
