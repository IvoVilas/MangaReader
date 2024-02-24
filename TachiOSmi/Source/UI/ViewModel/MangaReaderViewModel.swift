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

  @Published var pages: [ImageViewModel]

  private let chapterId: String
  private let restRequester: RestRequester

  private var observers = Set<AnyCancellable>()

  init(
    chapterId: String,
    restRequester: RestRequester
  ) {
    self.chapterId     = chapterId
    self.restRequester = restRequester

    pages = []

    $pages.sink { pages in
      for page in pages {
        Task { await page.loadImage() }
      }
    }.store(in: &observers)
  }
}

extension MangaReaderViewModel {

  func viewDidAppear() {
    Task { @MainActor in
      print("MangaReaderViewModel -> Starting chapter download")
      pages = []

      let json: [String : Any] = await restRequester.makeGetRequest(url: "https://api.mangadex.org/at-home/server/\(chapterId)")

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

      let pages = data.map {
        ImageViewModel(
          url: "\(baseUrl)/data/\(hash)/\($0)",
          restRequester: restRequester
        )
      }

      self.pages = pages
      print("MangaReaderViewModel -> Ending chapter download")
    }
  }

}

final class ImageViewModel: ObservableObject {

  @Published var page: UIImage?
  @Published var isLoading: Bool

  let url: String
  private let restRequester: RestRequester

  init(
    url: String,
    restRequester: RestRequester
  ) {
    self.url           = url
    self.restRequester = restRequester

    page      = nil
    isLoading = true
  }

  func loadImage() async {
    Task { @MainActor in
      self.isLoading = true
    }

    let data: Data? = await restRequester.makeGetRequest(url: url)

    Task { @MainActor [data] in
      if let data {
        page = UIImage(data: data)
      } else {
        page = UIImage.coverNotFound
      }

      self.isLoading = false
    }
  }

}
