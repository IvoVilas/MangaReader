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
  private let viewMoc: NSManagedObjectContext

  private let details: CurrentValueSubject<MangaModel, Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var detailsPublisher: AnyPublisher<MangaModel, Never> {
    details.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  init(
    source: Source,
    manga: MangaSearchResult,
    delegate: DetailsDelegateType,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    viewMoc: NSManagedObjectContext
  ) {
    mangaId = manga.id

    self.source = source
    self.delegate = delegate
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.authorCrud = authorCrud
    self.tagCrud = tagCrud
    self.viewMoc = viewMoc

    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
    details = CurrentValueSubject(
      MangaModel(
        id: manga.id,
        title: manga.title,
        description: nil,
        isSaved: manga.isSaved,
        source: source,
        status: .unknown,
        readingDirection: .leftToRight,
        cover: manga.cover,
        tags: [],
        authors: []
      )
    )
  }

  // Setups initial data
  // Prioritize local data
  // We update cover and everything else separately in case the cover request fails
  func setupData() async {
    print("MangaDetailsDatasource -> Start manga details fetch")

    var erro: DatasourceError?

    do {
      await MainActor.run {
        state.valueOnMain = .loading
        error.valueOnMain = nil
      }

      let mangaModel: MangaModel
      var didRequest = false

      let cover = try await viewMoc.perform {
        try self.coverCrud.getCoverData(for: self.mangaId, moc: self.viewMoc)
      }

      if let cover {
        await update(cover: cover)

        let manga = try await viewMoc.perform {
          try self.mangaCrud.getManga(self.mangaId, moc: self.viewMoc)
        }

        if let manga {
          mangaModel = .from(manga, cover: cover)
        } else {
          let data = try await delegate.fetchDetails(mangaId)

          didRequest = true
          mangaModel = data.convertToModel(source: source, cover: cover)
        }

        await update(using: mangaModel)
      } else {
        let data = try await delegate.fetchDetails(mangaId)
        let model = data.convertToModel(source: source)

        await update(using: model)

        let cover = try await delegate.fetchCover(
          mangaId: mangaId,
          coverInfo: data.coverInfo
        )

        await update(cover: cover)

        didRequest = true
        mangaModel = model
      }

      if didRequest {
        try await updateDatabase(mangaModel)
      }
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      state.valueOnMain = .normal
      error.valueOnMain = erro
    }

    print("MangaDetailsDatasource -> Ended manga details fetch")
  }

  func refresh() async {
    print("MangaDetailsDatasource -> Start manga refresh")

    var erro: DatasourceError?

    do {
      await MainActor.run {
        state.valueOnMain = .loading
        error.valueOnMain = nil
      }

      let data = try await delegate.fetchDetails(mangaId)
      let (isSaved, readingDirection) = await fetchSavedMangaDetails(mangaId)
      let model = data.convertToModel(
        source: source,
        isSaved: isSaved,
        readingDirection: readingDirection
      )

      await update(using: model)

      let cover = try await delegate.fetchCover(
        mangaId: mangaId,
        coverInfo: data.coverInfo
      )

      await update(cover: cover)

      try await updateDatabase(data.convertToModel(source: source, cover: cover))
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      state.valueOnMain = .normal
      error.valueOnMain = erro
    }

    print("MangaDetailsDatasource -> Ended manga details refresh")
  }

  @MainActor
  private func update(
    using manga: MangaModel
  ) {
    details.valueOnMain = manga
  }

  @MainActor
  private func update(
    cover: Data
  ) {
    let manga = details.valueOnMain

    details.valueOnMain = MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.description,
      isSaved: manga.isSaved,
      source: manga.source,
      status: manga.status,
      readingDirection: manga.readingDirection,
      cover: cover,
      tags: manga.tags,
      authors: manga.authors
    )
  }

}

// MARK: Database
extension DetailsDatasource {

  private func fetchSavedMangaDetails(
    _ mangaId: String
  ) async -> (Bool, ReadingDirection) {
    await viewMoc.perform {
      guard let manga = try? self.mangaCrud.getManga(
        mangaId,
        moc: self.viewMoc
      ) else {
        return (false, .leftToRight)
      }

      return (manga.isSaved, .safeInit(from: manga.readingDirection))
    }
  }

  private func updateDatabase(
    _ manga: MangaModel
  ) async throws {
    try await viewMoc.perform {
      let mangaMO = try self.mangaCrud.createOrUpdateManga(
        id: manga.id,
        title: manga.title,
        synopsis: manga.description,
        status: manga.status,
        source: self.source,
        moc: self.viewMoc
      )

      if let cover = manga.cover {
        _ = try self.coverCrud.createOrUpdateEntity(
          mangaId: manga.id,
          data: cover,
          moc: self.viewMoc
        )
      }

      // For now, we only store one author
      if let author = manga.authors.first {
        _ = try self.authorCrud.createOrUpdateAuthor(
          id: author.id,
          name: author.name,
          manga: mangaMO,
          moc: self.viewMoc
        )
      }

      for tag in manga.tags {
        _ = try self.tagCrud.createOrUpdateTag(
          id: tag.id,
          title: tag.title,
          manga: mangaMO,
          moc: self.viewMoc
        )
      }

      if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
    }
  }

}

