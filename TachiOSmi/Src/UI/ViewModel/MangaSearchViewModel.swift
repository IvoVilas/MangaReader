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

@Observable
final class MangaSearchViewModel {

  var sourceName: String
  var results: [MangaSearchResult]
  var input: String
  var isLoading: Bool
  var error: DatasourceError?

  private let source: Source
  private let datasource: SearchDatasource

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
    datasource: SearchDatasource
  ) {
    self.source = source
    self.datasource = datasource

    sourceName = source.name
    results = []
    input = ""
    isLoading = false
    error = nil

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

}

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

  func buildMangaDetailsViewModel(
    _ manga: MangaSearchResult
  ) -> MangaDetailsViewModel {
    return MangaDetailsViewModel(
      source: source,
      manga: manga,
      mangaCrud: AppEnv.env.mangaCrud,
      chapterCrud: AppEnv.env.chapterCrud,
      coverCrud: AppEnv.env.coverCrud,
      authorCrud: AppEnv.env.authorCrud,
      tagCrud: AppEnv.env.tagCrud,
      httpClient: AppEnv.env.httpClient,
      systemDateTime: AppEnv.env.systemDateTime,
      viewMoc: source.viewMoc
    )
  }

}
