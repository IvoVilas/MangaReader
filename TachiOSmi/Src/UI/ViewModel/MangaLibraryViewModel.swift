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

  @Published var mangas: [MangaLibraryProvider.MangaWrapper]
  @Published var layout: CollectionLayout
  @Published var gridSize: CGFloat
  @Published var sortOrder: SortOrder

  private let provider: MangaLibraryProvider
  private let store: AppOptionsStore

  private var observers = Set<AnyCancellable>()

  init(
    provider: MangaLibraryProvider,
    optionsStore: AppOptionsStore
  ) {
    self.provider = provider
    self.store = optionsStore

    mangas = []
    layout = optionsStore.libraryLayout
    gridSize = CGFloat(optionsStore.libraryGridSize)
    sortOrder = SortOrder(
      sortBy: optionsStore.librarySortBy,
      ascending: optionsStore.librarySortAscending
    )

    $gridSize
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.changeGridSize(to: Int($0)) }
      .store(in: &observers)

    Publishers.CombineLatest(
      provider.$mangas,
      $sortOrder
    )
    .map { (mangas, sortOrder) -> [MangaLibraryProvider.MangaWrapper] in
      mangas.sorted { MangaLibraryViewModel.sortMangas(lhs: $0, rhs: $1, sortOrder: sortOrder) }
    }
    .receive(on: DispatchQueue.main)
    .sink { [weak self] in self?.mangas = $0 }
    .store(in: &observers)
  }

  func changeLayout(to layout: CollectionLayout) {
    self.layout = layout

    store.changeProperty(.libraryLayout(layout))
  }

  func changeGridSize(to size: Int) {
    gridSize = CGFloat(size)

    store.changeProperty(.libraryGridSize(size))
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

}

extension MangaLibraryViewModel {

  struct SortOrder {
    let sortBy: MangasSortBy
    let ascending: Bool
  }

  private static func sortMangas(
    lhs: MangaLibraryProvider.MangaWrapper,
    rhs: MangaLibraryProvider.MangaWrapper,
    sortOrder: SortOrder
  ) -> Bool {
    let ascending = sortOrder.ascending
    let result: Bool

    switch sortOrder.sortBy {
    case .title:
      result = lhs.manga.title < rhs.manga.title

    case .totalChapters:
      result = lhs.totalChapters < rhs.totalChapters

    case .unreadCount:
      result = lhs.unreadChapters < rhs.unreadChapters

    case .latestChapter:
      guard let lhsDate = lhs.latestChapterDate else {
        return ascending
      }

      guard let rhsDate = rhs.latestChapterDate else {
        return !ascending
      }

      result = lhsDate < rhsDate
    }

    return ascending == result
  }

}
