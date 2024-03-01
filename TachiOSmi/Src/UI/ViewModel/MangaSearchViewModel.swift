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

  @Published var results: [MangaSearchResult]
  @Published var input: String
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

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
    datasource: SearchDatasource
  ) {
    self.datasource = datasource

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
    if input.isEmpty {
      await datasource.searchManga(searchValue)
    }
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
      chaptersDatasource: ChaptersDatasource(
        mangaId: manga.id,
        delegate: MangadexChaptersDelegate(
          httpClient: AppEnv.env.httpClient,
          chapterParser: AppEnv.env.chapterParser,
          systemDateTime: AppEnv.env.systemDateTime
        ),
        mangaCrud: AppEnv.env.mangaCrud,
        chapterCrud: AppEnv.env.chapterCrud,
        systemDateTime: AppEnv.env.systemDateTime
      ),
      detailsDatasource: DetailsDatasource(
        manga: manga,
        delegate: MangadexDetailsDelegate(
          httpClient: AppEnv.env.httpClient,
          coverCrud: AppEnv.env.coverCrud,
          mangaParser: AppEnv.env.mangaParser
        ),
        mangaCrud: AppEnv.env.mangaCrud,
        coverCrud: AppEnv.env.coverCrud,
        authorCrud: AppEnv.env.authorCrud,
        tagCrud: AppEnv.env.tagCrud
      )
    )
  }

}
