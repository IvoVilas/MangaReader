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

  @Published var title: String
  @Published var cover: UIImage?
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

    detailsDatasource.titlePublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.title = $0 }
      .store(in: &observers)

    detailsDatasource.descriptionPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.description = $0 }
      .store(in: &observers)

    detailsDatasource.statusPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.status = $0 }
      .store(in: &observers)

    detailsDatasource.authorsPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.authors = $0 }
      .store(in: &observers)

    detailsDatasource.tagsPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.tags = $0 }
      .store(in: &observers)

    detailsDatasource.coverPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] in self?.cover = UIImage(data: $0) }
      .store(in: &observers)

    chaptersDatasource.chaptersPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.chapters = $0 }
      .store(in: &observers)

    Publishers.CombineLatest(
      detailsDatasource.statePublisher,
      chaptersDatasource.statePublisher
    )
    .map { $0.0.isLoading || $0.1.isLoading }
    .removeDuplicates()
    .receive(on: DispatchQueue.main)
    .sink { [weak self] in self?.isLoading = $0 }
    .store(in: &observers)

    Publishers.CombineLatest(
      detailsDatasource.errorPublisher,
      chaptersDatasource.errorPublisher
    )
    .receive(on: DispatchQueue.main)
    .map {
      if let error = $0 { return error }

      if let error = $1 { return error }

      return nil
    }
    .sink { [weak self] in self?.error = $0 }
    .store(in: &observers)
  }

}

extension MangaDetailsViewModel {

  func setupData() async {
    await detailsDatasource.setupData()
    await chaptersDatasource.refresh()
  }

  func forceRefresh() async {
    await detailsDatasource.refresh()
    await chaptersDatasource.refresh()
  }

  func buildReaderViewModel(
    _ chapter: ChapterModel
  ) -> ChapterReaderViewModel {
    return ChapterReaderViewModel(
      datasource: ChapterPagesDatasource(
        chapter: chapter,
        httpClient: AppEnv.env.httpClient
      )
    )
  }

}
