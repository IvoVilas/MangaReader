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

final class DetailsDatasource<Source: SourceType> {

  let mangaId: String

  private let delegate: Source.DetailsDelegate
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
    manga: MangaSearchResult,
    delegate: Source.DetailsDelegate,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    viewMoc: NSManagedObjectContext = Source.database.viewMoc
  ) {
    mangaId = manga.id

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
        status: .unknown,
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

      let cover = try viewMoc.performAndWait {
        try coverCrud.getCoverData(for: mangaId, moc: viewMoc)
      }

      if let cover {
        await update(cover: cover)

        let manga = try viewMoc.performAndWait {
          try mangaCrud.getManga(mangaId, moc: viewMoc)
        }

        if let manga {
          mangaModel = .from(manga, cover: cover)
        } else {
          let data = try await delegate.fetchDetails(mangaId)

          didRequest = true
          mangaModel = data.convertToModel(cover: cover)
        }

        await update(using: mangaModel)
      } else {
        let data = try await delegate.fetchDetails(mangaId)
        let model = data.convertToModel()

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
      erro = catchError(error)
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
      let model = data.convertToModel()

      await update(using: model)

      let cover = try await delegate.fetchCover(
        mangaId: mangaId,
        coverInfo: data.coverInfo
      )

      await update(cover: cover)

      try await updateDatabase(data.convertToModel(cover: cover))
    } catch {
      erro = catchError(error)
    }

    await MainActor.run { [erro] in
      state.valueOnMain = .normal
      error.valueOnMain = erro
    }

    print("MangaDetailsDatasource -> Ended manga details refresh")
  }

  private func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      print("MangaSearchDelegate -> Task cancelled")

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as CrudError:
      print("MangaSearchDelegate -> Error during database operation: \(error.localizedDescription)")

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
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
      status: manga.status,
      cover: cover,
      tags: manga.tags,
      authors: manga.authors
    )
  }

}

// MARK: Database
extension DetailsDatasource {

  private func updateDatabase(
    _ manga: MangaModel
  ) async throws {
    try await viewMoc.perform {
      let mangaMO = try self.mangaCrud.createOrUpdateManga(
        id: manga.id,
        title: manga.title,
        synopsis: manga.description,
        status: manga.status,
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

