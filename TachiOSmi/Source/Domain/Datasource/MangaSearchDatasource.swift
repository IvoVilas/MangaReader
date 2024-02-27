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

        mangas.value.append(contentsOf: results.map { $0.convertToModel() })

        try Task.checkCancellation()
        Task {
          let updatedInfo = try await withThrowingTaskGroup(of: (String, UIImage?).self, returning: [(String, UIImage?)].self) { taskGroup in
            for data in results {
              taskGroup.addTask {
                let cover = try await self.getCover(for: data.id, fileName: data.coverFileName)

                return (data.id, cover)
              }
            }

            return try await taskGroup.reduce(into: [(String, UIImage?)]()) { partialResult, manga in
              partialResult.append(manga)
            }
          }

          self.addCoversTo(updatedInfo)
        }
        print("MangaSearchDatasource -> Search task ended")
      } catch {
        catchError(error)
      }

      self.state.value = .normal
      self.fetchTask   = nil
    }
  }

  func loadNextPage(
    _ searchValue: String
  ) async {
    if let fetchTask {
      await fetchTask.value
    }

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
        mangas.value.append(contentsOf: results.map { $0.convertToModel() })

        try Task.checkCancellation()
        Task {
          let updatedInfo = try await withThrowingTaskGroup(of: (String, UIImage?).self, returning: [(String, UIImage?)].self) { taskGroup in
            for data in results {
              taskGroup.addTask {
                let cover = try await self.getCover(for: data.id, fileName: data.coverFileName)

                return (data.id, cover)
              }
            }

            return try await taskGroup.reduce(into: [(String, UIImage?)]()) { partialResult, manga in
              partialResult.append(manga)
            }
          }

          self.addCoversTo(updatedInfo)
        }

        print("MangaSearchDatasource -> Finished loading page \(currentPage)")
      } catch {
        catchError(error)
      }

      self.fetchTask = nil
    }
  }

  private func catchError(_ error: Error) {
    switch error {
    case is CancellationError:
      print("MangaSearchDatasource -> Task cancelled")

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

  private func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaParser.MangaParsedData] {
    try Task.checkCancellation()

    let limit  = 15
    let offset = page * limit

    let results = try await makeSearchRequest(
      searchValue,
      limit: limit,
      offset: offset
    )

    return results
  }

  private func addCoversTo(
    _ info: [(String, UIImage?)]
  ) {
    info.forEach { addCoverTo($0.0, cover: $0.1) }
  }

  private func addCoverTo(
    _ id: String,
    cover: UIImage?
  ) {
    if let i = mangas.value.firstIndex(where: { $0.id == id }) {
      mangas.value[i].cover = cover
    }
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
        cover: manga.cover?.pngData(),
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
  ) async throws -> [MangaParser.MangaParsedData] {
    let data: [String: Any] = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga",
      parameters: [
        ("title", searchValue),
        ("order[followedCount]", "desc"),
        ("order[relevance]", "desc"),
        ("includes[]", "cover_art"),
        ("includes[]", "author"),
        ("limit", limit),
        ("offset", offset)
      ]
    )

    guard let dataJson = data["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    return try mangaParser.parseMangaSearchResponse(dataJson)
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
