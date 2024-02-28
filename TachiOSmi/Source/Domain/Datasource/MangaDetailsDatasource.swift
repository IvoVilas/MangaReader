//
//  MangaDetailsDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 26/02/2024.
//

import Foundation
import Combine
import CoreData
import UIKit

final class MangaDetailsDatasource {

  let mangaId: String

  private let httpClient: HttpClient
  private let mangaParser: MangaParser
  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let authorCrud: AuthorCrud
  private let tagCrud: TagCrud
  private let viewMoc: NSManagedObjectContext

  private let cover: CurrentValueSubject<Data?, Never>
  private let title: CurrentValueSubject<String, Never>
  private let description: CurrentValueSubject<String?, Never>
  private let status: CurrentValueSubject<MangaStatus, Never>
  private let authors: CurrentValueSubject<[AuthorModel], Never>
  private let tags: CurrentValueSubject<[TagModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var coverPublisher: AnyPublisher<Data?, Never> {
    cover.eraseToAnyPublisher()
  }

  var titlePublisher: AnyPublisher<String, Never> {
    title.eraseToAnyPublisher()
  }

  var descriptionPublisher: AnyPublisher<String?, Never> {
    description.eraseToAnyPublisher()
  }

  var statusPublisher: AnyPublisher<MangaStatus, Never> {
    status.eraseToAnyPublisher()
  }

  var authorsPublisher: AnyPublisher<[AuthorModel], Never> {
    authors.eraseToAnyPublisher()
  }

  var tagsPublisher: AnyPublisher<[TagModel], Never> {
    tags.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  init(
    manga: MangaModel,
    httpClient: HttpClient,
    mangaParser: MangaParser,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    mangaId = manga.id

    self.httpClient  = httpClient
    self.mangaParser = mangaParser
    self.mangaCrud   = mangaCrud
    self.coverCrud   = coverCrud
    self.authorCrud  = authorCrud
    self.tagCrud     = tagCrud
    self.viewMoc     = viewMoc

    cover       = CurrentValueSubject(manga.cover)
    title       = CurrentValueSubject(manga.title)
    description = CurrentValueSubject(manga.description)
    status      = CurrentValueSubject(manga.status)
    authors     = CurrentValueSubject(manga.authors)
    tags        = CurrentValueSubject(manga.tags)
    state       = CurrentValueSubject(.starting)
    error       = CurrentValueSubject(nil)
  }

  // Setups initial data
  // Prioritize local data
  // We update cover and everything else separately in case the cover request fails
  func setupData() async {
    do {
      print("MangaDetailsDatasource -> Start manga details fetch")
      state.value = .loading

      let mangaModel: MangaModel
      var didRequest = false

      if let cover = try coverCrud.getCoverData(for: mangaId, moc: viewMoc) {
        self.cover.value = cover

        if let manga = try mangaCrud.getManga(mangaId, moc: viewMoc) {
          mangaModel = .from(manga, cover: cover)
        } else {
          let parsedData = try await makeMangaIndexRequest()

          didRequest = true
          mangaModel = parsedData.convertToModel(cover: cover)
        }

        update(with: mangaModel)
      } else {
        let parsedData = try await makeMangaIndexRequest()

        update(with: parsedData.convertToModel())

        let cover = try await makeCoverRequest(fileName: parsedData.coverFileName)

        self.cover.value = cover

        didRequest = true
        mangaModel = parsedData.convertToModel(cover: cover)
      }

      if didRequest {
        try await updateDatabase(mangaModel)
      }
    } catch {
      catchError(error)
    }

    state.value = .normal
    print("MangaDetailsDatasource -> Ended manga details fetch")
  }

  func refresh() async {
    do {
      print("MangaDetailsDatasource -> Start manga details fetch")
      state.value = .loading

      let parsedData = try await makeMangaIndexRequest()

      update(with: parsedData.convertToModel())

      let cover = try await makeCoverRequest(fileName: parsedData.coverFileName)

      self.cover.value = cover

      try await updateDatabase(parsedData.convertToModel(cover: cover))
    } catch {
      catchError(error)
    }

    state.value = .normal
    print("MangaDetailsDatasource -> Ended manga details fetch")
  }

  private func update(
    with manga: MangaModel
  ) {
    title.value       = manga.title
    description.value = manga.description
    status.value      = manga.status
    authors.value     = manga.authors
    tags.value        = manga.tags
  }

}

// MARK: Error
extension MangaDetailsDatasource {

  private func catchError(_ error: Error) {
    switch error {
    case is CancellationError:
      print("MangaDetailsDatasource -> Task cancelled")

    case let error as ParserError:
      self.error.value = .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      self.error.value = .networkError(error.localizedDescription)

    case let error as CrudError:
      self.error.value = .databaseError(error.localizedDescription)

    default:
      self.error.value = .unexpectedError(error.localizedDescription)
    }
  }

}

// MARK: Database
extension MangaDetailsDatasource {

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

// MARK: Network
extension MangaDetailsDatasource {

  private func makeMangaIndexRequest() async throws -> MangaParser.MangaParsedData  {
    let json = try! await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga/\(mangaId)",
      parameters: [
        ("includes[]", "author"),
        ("includes[]", "cover_art")
      ]
    )

    guard let data = json["data"] as? [String: Any] else {
      throw ParserError.parameterNotFound("data")
    }

    return try mangaParser.parseMangaIndexResponse(data)
  }

  private func getCover(
    fileName: String
  ) async throws -> Data {
    if let localCoverData = try coverCrud.getCoverData(for: mangaId, moc: viewMoc) {
      return localCoverData
    }

    let remoteCoverData = try await makeCoverRequest(fileName: fileName)

    return remoteCoverData
  }

  private func makeCoverRequest(
    fileName: String
  ) async throws -> Data {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(mangaId)/\(fileName).256.jpg"
    )
  }

}
