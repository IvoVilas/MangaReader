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

  private let chaptersDatasource: MangaChapterDatasource
  private let detailsDatasource: MangaDetailsDatasource

  @Published var cover: UIImage?
  @Published var title: String
  @Published var description: String?
  @Published var status: MangaStatus
  @Published var authors: [AuthorModel]
  @Published var tags: [TagModel]
  @Published var chapters: [ChapterModel]
  @Published var isLoading: Bool
  @Published var isImageLoading: Bool
  @Published var error: DatasourceError?

  private var observers = Set<AnyCancellable>()

  init(
    chaptersDatasource: MangaChapterDatasource,
    detailsDatasource: MangaDetailsDatasource
  ) {
    self.chaptersDatasource = chaptersDatasource
    self.detailsDatasource  = detailsDatasource

    cover          = nil
    title          = ""
    status         = .unknown
    authors        = []
    tags           = []
    chapters       = []
    isLoading      = false
    isImageLoading = false

    chaptersDatasource.chaptersPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.chapters = $0 }
      .store(in: &observers)

    chaptersDatasource.errorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.error = $0 }
      .store(in: &observers)

    chaptersDatasource.statePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        switch state {
        case .loading, .starting:
          self?.isLoading = true

        default:
          self?.isLoading = false
        }
      }
      .store(in: &observers)

    detailsDatasource.coverPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.cover = $0 }
      .store(in: &observers)

    detailsDatasource.titlePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.title = $0 }
      .store(in: &observers)

    detailsDatasource.descriptionPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.description = $0 }
      .store(in: &observers)

    detailsDatasource.statusPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.status = $0 }
      .store(in: &observers)

    detailsDatasource.authorsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.authors = $0 }
      .store(in: &observers)

    detailsDatasource.tagsPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.tags = $0 }
      .store(in: &observers)

    detailsDatasource.statePublisher
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

  func setupData() async {
    switch chaptersDatasource.stateValue {
    case .starting:
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask { await self.chaptersDatasource.refresh() }
        taskGroup.addTask { await self.detailsDatasource.setupData() }
      }

    default:
      break
    }
  }

  func forceRefresh() {
    Task {
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask { await self.chaptersDatasource.refresh(isForceRefresh: true) }
        taskGroup.addTask { await self.detailsDatasource.refresh() }
      }
    }
  }

  func buildChapterReaderViewModel(
    for id: String
  ) -> MangaReaderViewModel {
    return MangaReaderViewModel(
      chapterId: id,
      httpClient: AppEnv.env.httpClient
    )
  }

}
