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

  private var currentPage: Int? = nil

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

  func searchManga(
    _ searchValue: String
  ) async {
    if let fetchTask {
      fetchTask.cancel()

      await fetchTask.value
    }

    state.value  = .loading
    mangas.value = []
    error.value  = nil
    currentPage  = 0

    fetchTask = Task { [weak self] in
      guard let self else { return }
      print("MangaSearchDatasource -> Search task started")

      do {
        let results = try await fetchSearchResults(searchValue, page: 0)

        self.mangas.value = results

        try Task.checkCancellation()
        try await PersistenceController.shared.container.performBackgroundTask { moc in
          try self.updateDatabase(
            with: results,
            moc: moc
          )
        }

        print("MangaSearchDatasource -> Search task ended")
      } catch is CancellationError {
        print("MangaSearchDatasource -> Search task cancelled")
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

  func loadNextPage(
    _ searchValue: String
  ) async {
    fetchTask = Task { [weak self] in
      guard let self, var currentPage else {
        print("MangaSearchDatasource -> There are no more results available")

        return
      }

      error.value = nil
      currentPage += 1

      print("MangaSearchDatasource -> Loading page \(currentPage)")

      do {
        let results = try await fetchSearchResults(searchValue, page: currentPage)

        guard !results.isEmpty else {
          print("MangaSearchDatasource -> There are no more results available")

          self.currentPage = nil

          return
        }

        self.currentPage = currentPage
        mangas.value.append(contentsOf: results)

        try Task.checkCancellation()
        try await PersistenceController.shared.container.performBackgroundTask { moc in
          try self.updateDatabase(
            with: results,
            moc: moc
          )
        }

        print("MangaSearchDatasource -> Finished loading page \(currentPage)")
      } catch is CancellationError {
        print("MangaSearchDatasource -> Loading page \(currentPage) task cancelled")
      } catch let error as ParserError {
        self.error.value = .errorParsingResponse(error.localizedDescription)
      } catch let error as HttpError {
        self.error.value = .networkError(error.localizedDescription)
      } catch let error as CrudError {
        self.error.value = .databaseError(error.localizedDescription)
      } catch {
        self.error.value = .unexpectedError(error.localizedDescription)
      }

      self.fetchTask = nil
    }
  }

  private func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaModel] {
    try Task.checkCancellation()

    let limit  = 10
    let offset = page * limit

    let results = try await makeSearchRequest(
      searchValue,
      limit: limit,
      offset: offset
    )

    return results
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
