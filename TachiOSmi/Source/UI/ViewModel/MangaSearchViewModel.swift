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
    Task.detached {
      await self.datasource.refresh(self.input)
    }
  }

}

extension MangaSearchViewModel {

  func buildMangaDetailsViewModel(
    _ manga: MangaModel
  ) -> MangaDetailsViewModel {
    let id = manga.id

    return MangaDetailsViewModel(
      chaptersDatasource: GlobalMangaChapterDatasource.getDatasourceFor(id, moc: moc),
      coverDatasource: GlobalMangaCoverDatasource.getDatasourceFor(id, moc: moc)
    )
  }

}

struct GlobalMangaChapterDatasource {

  static var datasources = [String: MangaChapterDatasource]()

  static func getDatasourceFor(
    _ id: String,
    moc: NSManagedObjectContext
  ) -> MangaChapterDatasource {
    if let datasource = datasources[id] {

      return datasource
    }

    let datasource = MangaChapterDatasource(
      mangaId: id,
      chapterParser: AppEnv.env.chapterParser,
      mangaCrud: AppEnv.env.mangaCrud,
      chapterCrud: AppEnv.env.chapterCrud,
      systemDateTime: AppEnv.env.systemDateTime,
      moc: moc
    )

    // TODO
    if datasources.count >= 50 {
      datasources.removeAll()
    }

    datasources[id] = datasource

    return datasource
  }

}

struct GlobalMangaCoverDatasource {

  static var datasources = [String: MangaCoverDatasource]()

  static func getDatasourceFor(
    _ id: String,
    moc: NSManagedObjectContext
  ) -> MangaCoverDatasource {
    if let datasource = datasources[id] {

      return datasource
    }

    let datasource = MangaCoverDatasource(
      mangaId: id,
      mangaParser: AppEnv.env.mangaParser,
      mangaCrud: AppEnv.env.mangaCrud,
      moc: moc
    )

    // TODO
    if datasources.count >= 50 {
      datasources.removeAll()
    }

    datasources[id] = datasource

    return datasource
  }

}
