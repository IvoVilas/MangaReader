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

  @Published var results: [MangaModel]
  @Published var input: String
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

  private let datasource: MangaSearchDatasource
  private let moc: NSManagedObjectContext

  private var observers   = Set<AnyCancellable>()

  init(
    datasource: MangaSearchDatasource,
    moc: NSManagedObjectContext
  ) {
    self.datasource = datasource
    self.moc        = moc

    results   = []
    input     = ""
    isLoading = false
    error     = nil

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

  func doSearch() {
    Task {
      await datasource.searchManga(input)
    }
  }

  func loadNext() {
    Task {
      await datasource.loadNextPage(input)
    }
  }

}

extension MangaSearchViewModel {

  func buildMangaDetailsViewModel(
    _ manga: MangaModel
  ) -> MangaDetailsViewModel {
    return MangaDetailsViewModel(
      chaptersDatasource: MangaChapterDatasource(
        mangaId: manga.id,
        httpClient: AppEnv.env.httpClient,
        chapterParser: AppEnv.env.chapterParser,
        mangaCrud: AppEnv.env.mangaCrud,
        chapterCrud: AppEnv.env.chapterCrud,
        systemDateTime: AppEnv.env.systemDateTime
      ),
      detailsDatasource: MangaDetailsDatasource(
        manga: manga,
        httpClient: AppEnv.env.httpClient,
        mangaParser: AppEnv.env.mangaParser,
        mangaCrud: AppEnv.env.mangaCrud,
        coverCrud: AppEnv.env.coverCrud,
        authorCrud: AppEnv.env.authorCrud,
        tagCrud: AppEnv.env.tagCrud
      )
    )
  }

}
