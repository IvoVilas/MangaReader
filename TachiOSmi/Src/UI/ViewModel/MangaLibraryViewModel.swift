//
//  MangaLibraryViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 31/05/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaLibraryViewModel: ObservableObject {

  @Published var mangas: [MangaWrapper]
  @Published var layout: CollectionLayout
  @Published var gridSize: CGFloat
  @Published var sortOrder: SortOrder
  @Published var refreshStatus: [String: RefreshLibraryUseCase.RefreshStatus]

  private let mangasProvider: MangaLibraryProvider
  private let chaptersInfoProvider: ChaptersInfoProvider
  private let store: AppOptionsStore

  private var observers = Set<AnyCancellable>()

  init(
    mangasProvider: MangaLibraryProvider,
    chaptersInfoProvider: ChaptersInfoProvider,
    refreshLibraryUseCase: RefreshLibraryUseCase,
    optionsStore: AppOptionsStore
  ) {
    self.mangasProvider = mangasProvider
    self.chaptersInfoProvider = chaptersInfoProvider
    self.store = optionsStore

    mangas = []
    refreshStatus = [:]
    layout = optionsStore.libraryLayout
    gridSize = CGFloat(optionsStore.libraryGridSize)
    sortOrder = SortOrder(
      sortBy: optionsStore.librarySortBy,
      ascending: optionsStore.librarySortAscending
    )

    $gridSize
      .receive(on: DispatchQueue.main)
      .map { Int($0) }
      .removeDuplicates()
      .sink { [weak self] in self?.changedGridSize(to: $0) }
      .store(in: &observers)

    // TODO: This a fix because info provider does not detect changes in the chapters of newly added mangas
    mangasProvider.mangas
      .dropFirst()
      .removeDuplicates()
      .sink { _ in
        chaptersInfoProvider.forceRefresh()
      }
      .store(in: &observers)

    Publishers.CombineLatest(
      mangasProvider.mangas,
      chaptersInfoProvider.info
    )
    .map { (mangas, chapters) -> [MangaWrapper] in
      mangas.map { manga in
        let info = chapters.first { $0.mangaId == manga.id }

        return MangaWrapper(
          manga: manga,
          totalChapters: info?.chapterCount ?? 0,
          unreadChapters: info?.unreadChapters ?? 0,
          latestChapterDate: info?.latestChapter
        )
      }
    }
    .combineLatest($sortOrder)
    .map { (mangas, sortOrder) -> [MangaWrapper] in
      mangas.sorted { MangaLibraryViewModel.sortMangas(lhs: $0, rhs: $1, sortOrder: sortOrder) }
    }
    .receive(on: DispatchQueue.main)
    .sink { [weak self] in self?.mangas = $0 }
    .store(in: &observers)

    refreshLibraryUseCase.$refreshStatus
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.refreshStatus = $0 }
      .store(in: &observers)
  }

  func changeLayout(to layout: CollectionLayout) {
    self.layout = layout

    store.changeProperty(.libraryLayout(layout))
  }

  func changeSortBy(to sort: MangasSortBy) {
    if sort == sortOrder.sortBy {
      let ascending = !sortOrder.ascending

      sortOrder = SortOrder(
        sortBy: sortOrder.sortBy,
        ascending: ascending
      )

      store.changeProperty(.librarySortAscending(ascending))
    } else {
      sortOrder = SortOrder(
        sortBy: sort,
        ascending: sortOrder.ascending
      )

      store.changeProperty(.librarySortBy(sort))
    }
  }

  private func changedGridSize(to size: Int) {
    store.changeProperty(.libraryGridSize(size))
  }

}

extension MangaLibraryViewModel {

  struct SortOrder {
    let sortBy: MangasSortBy
    let ascending: Bool
  }

  private static func sortMangas(
    lhs: MangaWrapper,
    rhs: MangaWrapper,
    sortOrder: SortOrder
  ) -> Bool {
    let ascending = sortOrder.ascending
    let result: Bool

    switch sortOrder.sortBy {
    case .title:
      result = lhs.manga.title <= rhs.manga.title

    case .totalChapters:
      if lhs.totalChapters == rhs.totalChapters {
        return lhs.manga.title <= rhs.manga.title
      }

      result = lhs.totalChapters < rhs.totalChapters

    case .unreadCount:
      if lhs.unreadChapters == rhs.unreadChapters {
        return lhs.manga.title <= rhs.manga.title
      }

      result = lhs.unreadChapters < rhs.unreadChapters

    case .latestChapter:
      guard let lhsDate = lhs.latestChapterDate else {
        return ascending
      }

      guard let rhsDate = rhs.latestChapterDate else {
        return !ascending
      }

      result = lhsDate <= rhsDate
    }

    return ascending == result
  }

}

extension MangaLibraryViewModel {

  struct MangaWrapper: Hashable, Identifiable {

    let manga: MangaSearchResult
    let totalChapters: Int
    let unreadChapters: Int
    let latestChapterDate: Date?

    var id: String { manga.id }

  }

}
