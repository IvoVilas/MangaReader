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

  private let baseUrl: String
  private let chapterHash: String
  private let data: [String]

  init(
    baseUrl: String,
    chapterHash: String,
    data: [String],
    restRequester: RestRequester
  ) {
    self.baseUrl     = baseUrl
    self.chapterHash = chapterHash
    self.data        = data
    self.pages       = []

    data.forEach {
      pages.append(
        ImageViewModel(
          url: "\(baseUrl)/data/\(chapterHash)/\($0)",
          restRequester: restRequester
        )
      )
    }
  }

}

extension MangaReaderViewModel {

  func viewDidAppear() {
    Task {
      await withTaskGroup(of: Void.self) { taskGroup in
        for page in pages {
          taskGroup.addTask { await page.loadImage() }
        }
      }
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
