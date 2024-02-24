//
//  MangaReaderViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaReaderViewModel: ObservableObject {

  enum Page: Identifiable {
    case remote(URL)
    case notFound(Int)

    var id: String {
      switch self {
      case .remote(let url):
        return url.absoluteString

      case .notFound(let pos):
        return "\(pos)"
      }
    }
  }

  @Published var pages: [Page]

  private let chapterId: String
  private let httpClient: HttpClient

  private var observers = Set<AnyCancellable>()

  init(
    chapterId: String,
    httpClient: HttpClient
  ) {
    self.chapterId  = chapterId
    self.httpClient = httpClient

    pages = []
  }

  func makePagesRequest() async {
    print("MangaReaderViewModel -> Starting chapter download")

    let json: [String : Any] = await httpClient.makeGetRequest(url: "https://api.mangadex.org/at-home/server/\(chapterId)")

    guard
      let baseUrl = json["baseUrl"] as? String,
      let chapterJson = json["chapter"] as? [String: Any],
      let hash = chapterJson["hash"] as? String,
      let data = chapterJson["data"] as? [String]
    else {
      print("MangaReaderViewModel Error -> Error parsing response")
      
      return
    }

    if pages.isEmpty {
      /// Handle error better
      print("Pages not found")
    }

    Task { @MainActor in
      pages = data.enumerated().map { index, data in
        if let url = URL(string: "\(baseUrl)/data/\(hash)/\(data)") {
          return .remote(url)
        }

        return .notFound(index)
      }
    }

    print("MangaReaderViewModel -> Ending chapter download")
  }

}
