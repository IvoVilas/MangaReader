//
//  MangaDetailsViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaDetailsViewModel<Source: SourceType>: ObservableObject {

  private let chaptersDatasource: ChaptersDatasource<Source>
  private let detailsDatasource: DetailsDatasource<Source>

  @Published var title: String
  @Published var cover: UIImage?
  @Published var description: String?
  @Published var status: MangaStatus
  @Published var authors: [AuthorModel]
  @Published var tags: [TagModel]
  @Published var chapters: [ChapterModel]
  @Published var chapterCount: Int
  @Published var isLoading: Bool
  @Published var isImageLoading: Bool
  @Published var error: DatasourceError?

  private var observers = Set<AnyCancellable>()

  init(
    chaptersDatasource: ChaptersDatasource<Source>,
    detailsDatasource: DetailsDatasource<Source>
  ) {
    self.chaptersDatasource = chaptersDatasource
    self.detailsDatasource = detailsDatasource

    cover          = nil
    title          = ""
    status         = .unknown
    authors        = []
    tags           = []
    chapters       = []
    chapterCount   = 0
    isLoading      = false
    isImageLoading = false

    detailsDatasource.detailsPublisher
      .map { $0.title }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.title = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.description }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.description = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.status }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.status = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.authors }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.authors = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.tags }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.tags = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .compactMap { $0.cover }
      .removeDuplicates()
      .map { UIImage(data: $0) }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.cover = $0 }
      .store(in: &observers)

    chaptersDatasource.chaptersPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.chapters = $0 }
      .store(in: &observers)

    chaptersDatasource.countPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.chapterCount = $0 }
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
    if chapters.isEmpty {
      await detailsDatasource.setupData()
      await chaptersDatasource.setupData()
    }
  }

  func forceRefresh() async {
    await detailsDatasource.refresh()
    await chaptersDatasource.refresh()
  }

  func loadNextChapters(_ id: String) async {
    if id == chapters.last?.id {
      await chaptersDatasource.loadNextPage()
    }
  }

  func buildReaderViewModel(
    _ chapter: ChapterModel
  ) -> ChapterReaderViewModel<Source> {
    return ChapterReaderViewModel(
      datasource: PagesDatasource(
        chapter: chapter,
        delegate: Source.PagesDelegate.init(
          httpClient: AppEnv.env.httpClient
        )
      )
    )
  }

}
