//
//  DetailsDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine
import CoreData
import UIKit

final class DetailsDatasource {

  let mangaId: String

  private let source: Source
  private let delegate: DetailsDelegateType
  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let authorCrud: AuthorCrud
  private let tagCrud: TagCrud
  private let appOptionsStore: AppOptionsStore
  private let moc: NSManagedObjectContext

  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  init(
    source: Source,
    mangaId: String,
    delegate: DetailsDelegateType,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    appOptionsStore: AppOptionsStore,
    moc: NSManagedObjectContext
  ) {
    self.mangaId = mangaId
    self.source = source
    self.delegate = delegate
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.authorCrud = authorCrud
    self.tagCrud = tagCrud
    self.appOptionsStore = appOptionsStore
    self.moc = moc

    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func refresh(
    force: Bool = false
  ) async {
    var erro: DatasourceError?

    do {
      await MainActor.run {
        state.valueOnMain = .loading
        error.valueOnMain = nil
      }

      if try await needsFetch(isForce: force) {
        print("MangaDetailsDatasource -> Starting manga details refresh...")

        let data = try await delegate.fetchDetails(mangaId)
        let cover = try? await delegate.fetchCover(mangaId: mangaId, coverInfo: data.coverInfo)

        try await updateDatabase(data, cover: cover)

        print("MangaDetailsDatasource -> Ended manga details refresh")
      }
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      state.valueOnMain = .normal
      error.valueOnMain = erro
    }
  }

  private func needsFetch(isForce: Bool) async throws -> Bool {
    if isForce {
      return true
    }

    let context = moc
    var needsFetch = false

    try await context.perform {
      needsFetch = try self.mangaCrud.getManga(self.mangaId, moc: context) == nil
    }

    return needsFetch
  }

}

// MARK: Database
extension DetailsDatasource {

  private func updateDatabase(
    _ manga: MangaDetailsParsedData,
    cover: Data?
  ) async throws {
    let context = moc

    try context.performAndWait {
      let mangaMO = try self.mangaCrud.createOrUpdateManga(
        id: manga.id,
        title: manga.title,
        synopsis: manga.description,
        status: manga.status,
        source: self.source,
        readingDirection: self.appOptionsStore.defaultDirection,
        moc: context
      )

      if let cover {
        _ = try self.coverCrud.createOrUpdateEntity(
          mangaId: manga.id,
          data: cover,
          moc: context
        )
      }

      // For now, we only store one author
      if let author = manga.authors.first {
        _ = try self.authorCrud.createOrUpdateAuthor(
          id: author.id,
          name: author.name,
          manga: mangaMO,
          moc: context
        )
      }

      for tag in manga.tags {
        _ = try self.tagCrud.createOrUpdateTag(
          id: tag.id,
          title: tag.title,
          manga: mangaMO,
          moc: context
        )
      }

      if !context.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
    }
  }

}

