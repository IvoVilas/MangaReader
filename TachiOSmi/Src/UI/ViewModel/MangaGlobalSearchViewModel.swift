//
//  MangaGlobalSearchViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class MangaGlobalSearchViewModel: ObservableObject {

  @Published var savedMangas: [String]
  @Published var input: String
  var sources: [SourceResultsViewModel]

  private let provider: MangaSearchProvider

  private var observers = Set<AnyCancellable>()

  init(
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    httpClient: HttpClientType,
    container: NSPersistentContainer
  ) {
    let moc = container.newBackgroundContext()
    let viewMoc = container.viewContext

    input = ""
    savedMangas = []
    provider = MangaSearchProvider(viewMoc: viewMoc)
    sources = Source.allSources().map {
      SourceResultsViewModel(
        source: $0,
        mangaCrud: mangaCrud,
        coverCrud: coverCrud,
        httpClient: httpClient,
        moc: moc
      )
    }

    provider.$savedMangas
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.savedMangas = $0 }
      .store(in: &observers)
  }

}

// MARK: Actions
extension MangaGlobalSearchViewModel {

  func doSearch() {
    if !input.isEmpty {
      for source in sources {
        source.doSearch(value: input)
      }
    }
  }

}

final class SourceResultsViewModel: ObservableObject, Identifiable {

  var id: String { source.id }

  let source: Source
  @Published var results: [MangaSearchResult]
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

  @Published var input: String
  let datasource: SearchDatasource

  private var observers = Set<AnyCancellable>()

  init(
    source: Source,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    httpClient: HttpClientType,
    moc: NSManagedObjectContext
  ) {
    self.source = source
    self.results = []
    self.isLoading = false
    self.error = nil
    self.input = ""

    self.datasource = SearchDatasource(
      source: source,
      delegate: source.searchDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      coverCrud: coverCrud,
      moc: moc
    )

    datasource.mangasPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.results = $0 }
      .store(in: &observers)

    datasource.statePublisher
      .removeDuplicates()
      .map { $0 == .loading }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.isLoading = $0 }
      .store(in: &observers)
  }

  func doSearch(value: String) {
    input = value

    Task {
      await datasource.searchManga(.query(value))
    }
  }

}
