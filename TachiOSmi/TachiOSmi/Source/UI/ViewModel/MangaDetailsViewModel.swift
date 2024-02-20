//
//  MangaDetailsViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaDetailsViewModel: ObservableObject {

  let chaptersDatasource: MangaChapterDatasource
  let coverDatasource: MangaCoverDatasource

  @Published var image: UIImage?
  @Published var title: String
  @Published var chapters: [ChapterModel]
  @Published var isLoading: Bool
  @Published var isImageLoading: Bool

  private var observers = Set<AnyCancellable>()

  init(
    chaptersDatasource: MangaChapterDatasource,
    coverDatasource: MangaCoverDatasource
  ) {
    self.chaptersDatasource = chaptersDatasource
    self.coverDatasource    = coverDatasource

    chapters       = []
    isLoading      = false
    isImageLoading = false
    image          = nil
    title          = "Jujutsu Kaisen"

    chaptersDatasource.chaptersPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.chapters = $0 }
      .store(in: &observers)

    chaptersDatasource.statePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        switch state {
        case .loading:
          self?.isLoading = true

        default:
          self?.isLoading = false
        }
      }
      .store(in: &observers)

    coverDatasource.imagePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.image = $0 }
      .store(in: &observers)

    coverDatasource.statePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        switch state {
        case .loading:
          self?.isLoading = true

        default:
          self?.isLoading = false
        }
      }
      .store(in: &observers)
  }

}

extension MangaDetailsViewModel {

  func onViewAppear() {
    switch chaptersDatasource.stateValue {
    case .starting:
      Task {
        await chaptersDatasource.refresh()
      }

    default:
      break
    }
  }

}
