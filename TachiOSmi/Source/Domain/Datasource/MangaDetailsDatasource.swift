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

  func setupData() async {
    do {
      state.value = .loading
      print("MangaDetailsDatasource -> Start manga details fetch")
      if let manga = try mangaCrud.getManga(mangaId, moc: viewMoc) {
        print("MangaDetailsDatasource -> Found local manga details")
        update(with: .from(manga))

        state.value = .normal

        return
      }

      print("MangaDetailsDatasource -> Will fetch manga details from remote")

      let parsedData = try await makeMangaIndexRequest()

      update(with: parsedData.convertToModel())

      let cover = try await getCover(fileName: parsedData.coverFileName)

      self.cover.value = cover

      try await viewMoc.perform {
        let manga = try self.mangaCrud.createOrUpdateManga(
          id: parsedData.id,
          title: parsedData.title,
          synopsis: parsedData.description,
          status: parsedData.status,
          moc: self.viewMoc
        )

        _ = try self.coverCrud.createEntity(
          mangaId: manga.id,
          data: cover,
          moc: self.viewMoc
        )

        // For now, we only store one author
        if let author = parsedData.authors.first {
          _ = try self.authorCrud.createOrUpdateAuthor(
            id: author.id,
            name: author.name,
            manga: manga,
            moc: self.viewMoc
          )
        }

        for tag in manga.tags {
          _ = try self.tagCrud.createOrUpdateTag(
            id: tag.id,
            title: tag.title,
            manga: manga,
            moc: self.viewMoc
          )
        }

        if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
          throw CrudError.saveError
        }
      }
    } catch let error as ParserError {
      print("MangaDetailsDatasource -> Error during parsing operation: \(error.localizedDescription)")
    } catch let error as HttpError {
      self.error.value = .networkError(error.localizedDescription)
    } catch let error as CrudError {
      print("MangaDetailsDatasource -> Error during database operation: \(error.localizedDescription)")
    } catch {
      self.error.value = .unexpectedError(error.localizedDescription)
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

      try await viewMoc.perform {
        let manga = try self.mangaCrud.createOrUpdateManga(
          id: parsedData.id,
          title: parsedData.title,
          synopsis: parsedData.description,
          status: parsedData.status,
          moc: self.viewMoc
        )

        // For now, we only store one author
        if let author = parsedData.authors.first {
          _ = try self.authorCrud.createOrUpdateAuthor(
            id: author.id,
            name: author.name,
            manga: manga,
            moc: self.viewMoc
          )
        }

        for tag in parsedData.tags {
          _ = try self.tagCrud.createOrUpdateTag(
            id: tag.id,
            title: tag.title,
            manga: manga,
            moc: self.viewMoc
          )
        }

        if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
          throw CrudError.saveError
        }
      }
    } catch let error as ParserError {
      print("MangaDetailsDatasource -> Error during parsing operation: \(error.localizedDescription)")
    } catch let error as HttpError {
      self.error.value = .networkError(error.localizedDescription)
    } catch let error as CrudError {
      print("MangaDetailsDatasource -> Error during database operation: \(error.localizedDescription)")
    } catch {
      self.error.value = .unexpectedError(error.localizedDescription)
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
