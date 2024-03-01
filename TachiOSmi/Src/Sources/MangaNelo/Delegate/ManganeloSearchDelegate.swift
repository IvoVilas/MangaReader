//
//  ManganeloSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import SwiftSoup
import Alamofire

final class ManganeloSearchDelegate: SearchDelegateType {

  private let httpClient: HttpClient

  init(
    httpClient: HttpClient
  ) {
    self.httpClient = httpClient
  }

  func fetchTrending(
    page: Int
  ) async throws -> [MangaParsedData] {
    let url = "https://m.manganelo.com/genre-all/\(page + 1)?type=topview"
    let html = try await fetchHtml(from: url)

    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let elements = try? doc.select("div.content-genres-item")
    else {
      throw ParserError.parsingError
    }

    let results = elements.compactMap { element -> Result? in
      guard
        let url = try? element.select("a[data-id]").attr("href"),
        let idComponent = url.components(separatedBy: "/").last,
        let id = idComponent.components(separatedBy: "-").last
      else {
        print("ManganeloSearchDelegate -> Parameter id not found")

        return nil
      }

      guard let title = try? element.select("h3 a").text() else {
        print("ManganeloSearchDelegate -> Parameter title not found")

        return nil
      }

      guard let url = try? element.select("img.img-loading").attr("src") else {
        print("ManganeloSearchDelegate -> Parameter cover not found")

        return nil
      }

      return Result(
        id: id,
        title: title,
        coverUrl: url
      )
    }

    return results.map {
      MangaParsedData(
        id: $0.id,
        title: $0.title,
        description: nil,
        status: .unknown,
        tags: [],
        authors: [],
        coverFileName: $0.coverUrl
      )
    }
  }

  func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaParsedData] {
    let url: String
    var set = CharacterSet.alphanumerics
    set.insert("_")

    if !searchValue.isEmpty {
      let noSpaces = searchValue.lowercased().replacingOccurrences(of: " ", with: "_")
      let noSpecialChars = String(noSpaces.unicodeScalars.filter(set.contains))
      url = "https://m.manganelo.com/search/story/\(noSpecialChars)?page=\(page + 1)"
    } else {
      url = "https://m.manganelo.com/genre-all?type=topview"
    }

    let html = try await fetchHtml(from: url)

    guard
      let doc: Document = try? SwiftSoup.parse(html),
      let elements = try? doc.select("div.search-story-item")
    else {
      throw ParserError.parsingError
    }

    let results = elements.compactMap { element -> Result? in
      guard
        let url = try? element.select("a[data-id]").attr("href"),
        let idComponent = url.components(separatedBy: "/").last,
        let id = idComponent.components(separatedBy: "-").last
      else {
        print("ManganeloSearchDelegate -> Parameter id not found")

        return nil
      }

      guard let title = try? element.select("h3 a").text() else {
        print("ManganeloSearchDelegate -> Parameter title not found")

        return nil
      }

      guard let url = try? element.select("img.img-loading").attr("src") else {
        print("ManganeloSearchDelegate -> Parameter cover not found")

        return nil
      }

      return Result(
        id: id,
        title: title,
        coverUrl: url
      )
    }

    return results.map {
      MangaParsedData(
        id: $0.id,
        title: $0.title,
        description: nil,
        status: .unknown,
        tags: [],
        authors: [],
        coverFileName: $0.coverUrl
      )
    }
  }
  
  func fetchCover(id: String, fileName: String) async throws -> Data {
    try await httpClient.makeDataGetRequest(url: fileName)
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

extension ManganeloSearchDelegate {

  struct Result {
    let id: String
    let title: String
    let coverUrl: String
  }

  private func fetchHtml(from url: String) async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url).responseString { response in
        switch response.result {
        case .success(let html):
          continuation.resume(returning: html)

        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

}
