//
//  MangaSearchViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class MangaSearchViewModel: ObservableObject {

  @Published var sourceName: String
  @Published var results: [MangaSearchResult]
  @Published var savedMangas: [String]
  @Published var input: String
  @Published var isSearching: Bool
  @Published var layout: CollectionLayout
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

  private let source: Source
  private let provider: MangaSearchProvider
  private let datasource: SearchDatasource
  private let store: AppOptionsStore

  private var searchValue: MangaSearchType {
    if input.isEmpty {
      return .trending
    } else {
      return .query(input)
    }
  }

  private var observers = Set<AnyCancellable>()

  init(
    source: Source,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    httpClient: HttpClientType,
    optionsStore: AppOptionsStore,
    container: NSPersistentContainer
  ) {
    self.source = source

    self.provider = MangaSearchProvider(
      viewMoc: container.viewContext
    )
    self.datasource = SearchDatasource(
      source: source,
      delegate: source.searchDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      coverCrud: coverCrud,
      moc: container.newBackgroundContext()
    )
    self.store = optionsStore

    sourceName = source.name
    results = []
    savedMangas = []
    input = ""
    isSearching = false
    layout = optionsStore.libraryLayout
    isLoading = false
    error = nil

    setupObservers()
  }

  init(
    input: String,
    datasource: SearchDatasource,
    optionsStore: AppOptionsStore,
    container: NSPersistentContainer
  ) {
    self.source = datasource.source
    self.datasource = datasource
    self.store = optionsStore
    self.provider = MangaSearchProvider(
      viewMoc: container.viewContext
    )

    self.input = input
    isSearching = true
    sourceName = source.name
    results = []
    savedMangas = []
    layout = optionsStore.libraryLayout
    isLoading = false
    error = nil

    setupObservers()
  }

  private func setupObservers() {
    provider.$savedMangas
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.savedMangas = $0 }
      .store(in: &observers)

    datasource.mangasPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.results = $0 }
      .store(in: &observers)

    datasource.errorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.error = $0 }
      .store(in: &observers)

    datasource.statePublisher
      .removeDuplicates()
      .map { $0.isLoading }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.isLoading = $0 }
      .store(in: &observers)
  }

  private static func toggleLayout(
    _ layout: CollectionLayout
  ) -> CollectionLayout {
    switch layout {
    case .normal:
      return .compact

    case .compact:
      return .list

    case .list:
      return .normal
    }
  }

}

// MARK: Actions
extension MangaSearchViewModel {

  func doSearch() async {
    await datasource.searchManga(searchValue)
  }

  func loadNextIfNeeded(_ id: String) async {
    if id == results.last?.id {
      if await datasource.hasMorePages {
        await datasource.loadNextPage(searchValue)
      }
    }
  }

  func toggleLayout() {
    let newLayout = MangaSearchViewModel.toggleLayout(layout)

    layout = newLayout

    store.changeProperty(.searchLayout(newLayout))
  }

}
