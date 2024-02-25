//
//  MangaSearchDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import Combine
import CoreData
import UIKit

final class MangaSearchDatasource {

  private let httpClient: HttpClient
  private let mangaParser: MangaParser
  private let mangaCrud: MangaCrud
  private let viewMoc: NSManagedObjectContext

  private let mangas: CurrentValueSubject<[MangaModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var mangasPublisher: AnyPublisher<[MangaModel], Never> {
    mangas.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  var stateValue: DatasourceState {
    state.value
  }

  private var fetchTask: Task<Void, Never>?

  init(
    httpClient: HttpClient,
    mangaParser: MangaParser,
    mangaCrud: MangaCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    self.httpClient  = httpClient
    self.mangaParser = mangaParser
    self.mangaCrud   = mangaCrud
    self.viewMoc     = viewMoc

    mangas = CurrentValueSubject([])
    state  = CurrentValueSubject(.starting)
    error  = CurrentValueSubject(nil)

    setupInitalValues()
  }

  func setupInitalValues() {
    do {
      mangas.value = try mangaCrud
        .getAllMangasWithChapters(moc: viewMoc)
        .map { .from($0) }
    } catch let error as CrudError {
      self.error.value = .databaseError(error.localizedDescription)
    } catch {
      self.error.value = .unexpectedError(error.localizedDescription)
    }

    state.value = .normal
  }

  /**
   Refreshes the datasource

   - Parameters:
   - searchValue: The filter applied when searching

   ## You should know
   - This method is meant to be called on a background thread for increased performance.
   - It is not garanted that the published changes are stored in the database.

   ## How it works:
   1. We make each api page request and append it's result to the publisher
   2. For each manga we receive we will try to fetch de cover from the database and if not present, request it from the ap
   3. We will then update the publisher value with the covers
   4. At last, we update the database using the values currently published
   */
  func refresh(
    _ searchValue: String
  ) async {
    if let fetchTask {
      fetchTask.cancel()

      await fetchTask.value
    }

    state.value  = .loading
    mangas.value = []
    error.value  = nil

    fetchTask = Task { [weak self] in
      guard let self else { return }

      do {
        try await makeRefresh(searchValue)
      } catch is CancellationError {
        print("MangaSearchDatasource -> Fetch task cancelled")
      } catch let error as ParserError {
        self.error.value = .errorParsingResponse(error.localizedDescription)
      } catch let error as HttpError {
        self.error.value = .networkError(error.localizedDescription)
      } catch let error as CrudError {
        self.error.value = .databaseError(error.localizedDescription)
      } catch {
        self.error.value = .unexpectedError(error.localizedDescription)
      }

      self.state.value = .normal
      self.fetchTask   = nil
    }
  }

  private func makeRefresh(
    _ searchValue: String
  ) async throws {
    print("MangaSearchDatasource -> Fetch task started")

    var results    = [MangaModel]()
    let limit      = 10
    var offset     = 0
    let max        = searchValue == "" ? 30 : 100

    // TODO: Implement user pagination
    // TODO: TaskGroup
    while true && offset < max {
      try Task.checkCancellation()

      let result = try await makeSearchRequest(
          searchValue,
          limit: limit,
          offset: offset
        )

      if result.isEmpty { break }

      offset += limit

      results.append(contentsOf: result)

      mangas.value = results
    }

    state.value = .normal

    try Task.checkCancellation()

    try await PersistenceController.shared.container.performBackgroundTask { moc in
      try self.updateDatabase(
        with: results,
        moc: moc
      )
    }

    print("MangaSearchDatasource -> Fetch task ended")
  }

  private func updateResult(
    _ id: String,
    withCover cover: UIImage?
  ) -> MangaModel? {
    if let i = mangas.value.firstIndex(where: { $0.id == id }) {
      let manga = mangas.value[i]

      let updated = MangaModel(
        id: manga.id,
        title: manga.title,
        description: manga.description,
        status: manga.status,
        cover: cover,
        tags: manga.tags
      )

      mangas.value[i] = updated

      return updated
    }

    return nil
  }

  private func updateDatabase(
    with mangas: [MangaModel],
    moc: NSManagedObjectContext
  ) throws {
    for manga in mangas {
      _ = try mangaCrud.createOrUpdateManga(
        id: manga.id,
        title: manga.title,
        about: manga.description,
        status: manga.status,
        moc: moc
      )
    }

    if !moc.saveIfNeeded(rollbackOnError: true).isSuccess {
      throw CrudError.saveError
    }
  }

}

// MARK: Search
extension MangaSearchDatasource {

  private func makeSearchRequest(
    _ searchValue: String,
    limit: Int,
    offset: Int
  ) async throws -> [MangaModel] {
    let data: [String: Any] = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga",
      parameters: [
        "title": searchValue,
        "order[followedCount]": "desc",
        "order[relevance]": "desc",
        "includes[]": "cover_art",
        "limit": limit,
        "offset": offset
      ]
    )

    guard let dataJson = data["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    let parsedData = try mangaParser.parseMangaSearchResponse(dataJson)

    return try await withThrowingTaskGroup(of: MangaModel.self, returning: [MangaModel].self) { taskGroup in
      for data in parsedData {
        taskGroup.addTask {
          let cover = try await self.getCover(for: data.id, fileName: data.coverFileName)

          return data.convertToModel(cover: cover)
        }
      }

      return try await taskGroup.reduce(into: [MangaModel]()) { partialResult, manga in
        partialResult.append(manga)
      }
    }
  }

}

// MARK: Cover
extension MangaSearchDatasource {

  private func getCover(
    for id: String,
    fileName: String
  ) async throws -> UIImage? {
    if let localCoverData = try mangaCrud.getMangaCover(id, moc: viewMoc) {
      return UIImage(data: localCoverData)
    }

    if let remoteCoverData = try await makeCoverRequest(id: id, coverFileName: fileName) {
      return UIImage(data: remoteCoverData)
    }

    return nil
  }

  private func makeCoverRequest(
    id: String,
    coverFileName: String
  ) async throws -> Data? {
    return try await httpClient.makeDataGetRequest(
      url: "https://uploads.mangadex.org/covers/\(id)/\(coverFileName).256.jpg"
    )
  }

}
