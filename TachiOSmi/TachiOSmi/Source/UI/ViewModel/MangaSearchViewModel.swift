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

  private let datasource: MangaSearchDatasource
  private let moc: NSManagedObjectContext

//  private var datasources = [String: MangaChapterDatasource]()
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

    datasource.mangasPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.results = $0 }
      .store(in: &observers)

    datasource.statePublisher
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
  }

  func doSearch() {
    Task {
      await datasource.refresh(input)
    }
  }

}

extension MangaSearchViewModel {

  func buildMangaDetailsViewModel(
    _ manga: MangaModel
  ) -> MangaDetailsViewModel {
//    if let datasource = datasources[manga.id] {
//      return MangaDetailsViewModel(
//        chaptersDatasource: datasource,
//        coverDatasource:
//      )
//    }
//
//    if datasources.keys.count >= 10 {
//      datasources.removeAll()
//    }
//
//    let datasource = MangaChapterDatasource(
//      mangaId: manga.id,
//      chapterParser: AppEnv.env.chapterParser,
//      mangaCrud: AppEnv.env.mangaCrud,
//      chapterCrud: AppEnv.env.chapterCrud,
//      systemDateTime: AppEnv.env.systemDateTime,
//      moc: moc
//    )
//
//    datasources[manga.id] = datasource
//
//    return MangaDetailsViewModel(
//      datasource: datasource
//    )

    return MangaDetailsViewModel(
      chaptersDatasource: MangaChapterDatasource(
        mangaId: manga.id,
        chapterParser: AppEnv.env.chapterParser,
        mangaCrud: AppEnv.env.mangaCrud,
        chapterCrud: AppEnv.env.chapterCrud,
        systemDateTime: AppEnv.env.systemDateTime,
        moc: moc
      ), 
      coverDatasource: MangaCoverDatasource(
        mangaId: manga.id,
        mangaParser: AppEnv.env.mangaParser,
        mangaCrud: AppEnv.env.mangaCrud,
        moc: moc
      )
    )
  }

}
