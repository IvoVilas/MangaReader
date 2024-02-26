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
  private let viewMoc: NSManagedObjectContext

  private let cover: CurrentValueSubject<UIImage?, Never>
  private let title: CurrentValueSubject<String, Never>
  private let description: CurrentValueSubject<String?, Never>
  private let status: CurrentValueSubject<MangaStatus, Never>
  private let authors: CurrentValueSubject<[AuthorModel], Never>
  private let tags: CurrentValueSubject<[TagModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  private var currentPage: Int? = nil

  var coverPublisher: AnyPublisher<UIImage?, Never> {
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

  private var fetchTask: Task<Void, Never>?

  init(
    manga: MangaModel,
    httpClient: HttpClient,
    mangaParser: MangaParser,
    mangaCrud: MangaCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    mangaId = manga.id

    self.httpClient  = httpClient
    self.mangaParser = mangaParser
    self.mangaCrud   = mangaCrud
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
      if let manga = try mangaCrud.getManga(mangaId, moc: viewMoc) {
        update(with: .from(manga))

        return
      }

      state.value = .loading

      let parsedData = try await makeMangaIndexRequest()

      update(with: parsedData.convertToModel())

      // TODO: Store on database
      if let cover = try await getCover(fileName: parsedData.coverFileName) {
        self.cover.value = cover
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
  }

  func refresh() async {
    do {
      state.value = .loading

      let parsedData = try await makeMangaIndexRequest()

      update(with: parsedData.convertToModel())

      // TODO: Store on database
      let coverData = try await makeCoverRequest(fileName: parsedData.coverFileName)

      if let cover = UIImage(data: coverData) {
        self.cover.value = cover
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
      parameters: ["includes[]": "author"]
    )

    guard let data = json["data"] as? [String: Any] else {
      throw ParserError.parameterNotFound("data")
    }

    return try mangaParser.parseMangaIndexResponse(data)
  }

  private func getCover(
    fileName: String
  ) async throws -> UIImage? {
    if let localCoverData = try mangaCrud.getMangaCover(mangaId, moc: viewMoc) {
      return UIImage(data: localCoverData)
    }

    let remoteCoverData = try await makeCoverRequest(fileName: fileName)

    return UIImage(data: remoteCoverData)
  }

  private func makeCoverRequest(
    fileName: String
  ) async throws -> Data {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(mangaId)/\(fileName).256.jpg"
    )
  }

}
