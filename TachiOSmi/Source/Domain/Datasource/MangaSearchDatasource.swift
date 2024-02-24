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

  enum VarUpdate<T> {
    case skip
    case update(T)
  }

  private let restRequester: RestRequester
  private let mangaParser: MangaParser
  private let mangaCrud: MangaCrud
  private let viewMoc: NSManagedObjectContext

  private let mangas: CurrentValueSubject<[MangaModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>

  var mangasPublisher: AnyPublisher<[MangaModel], Never> {
    mangas.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var stateValue: DatasourceState {
    state.value
  }

  private var fetchTask: Task<Void, Never>?

  init(
    restRequester: RestRequester,
    mangaParser: MangaParser,
    mangaCrud: MangaCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    self.restRequester = restRequester
    self.mangaParser   = mangaParser
    self.mangaCrud     = mangaCrud
    self.viewMoc       = viewMoc

    mangas = CurrentValueSubject([])
    state  = CurrentValueSubject(.starting)

    setupInitalValues()
  }

  func setupInitalValues() {
    mangas.value = mangaCrud
      .getAllMangasWithChapters(moc: viewMoc)
      .map { .from($0) }

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
   1. We make each api page request (background) and append it's result to the publisher (main)
   2. For each manga we receive we will try to fetch de cover from the database and if not present, request it from the api (background detached)
   3. We will then update the publisher value with the covers (main)
   4. At last, we update the database using the values currently published
   */
  func refresh(
    _ searchValue: String
  ) async {
    if let fetchTask {
      fetchTask.cancel()

      await fetchTask.value
    }

    state.value = .loading
    mangas.value = []

    fetchTask = Task { [weak self] in
      guard let self else {
        self?.state.value = .cancelled
        self?.fetchTask   = nil

        return
      }

      do {
        try await makeRefresh(searchValue)
      } catch {
        self.state.value = .cancelled

        print("MangaSearchDatasource -> Fetch task cancelled")
      }

      self.fetchTask = nil
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

      let result = await Task.detached { [searchValue, limit, offset] () -> [MangaModel] in
        return await self.makeSearchRequest(
          searchValue,
          limit: limit,
          offset: offset
        )
      }.value

      if result.isEmpty { break }

      offset += limit

      results.append(contentsOf: result)

      self.mangas.value = results
    }

    try Task.checkCancellation()

    state.value = .normal

    try Task.checkCancellation()

    await PersistenceController.shared.container.performBackgroundTask { moc in
      print("MangaSearchDatasource -> Saving \(results.count) items into the database")

      self.updateDatabase(with: results, moc: moc)

      if !moc.saveIfNeeded(rollbackOnError: true).isSuccess {
        print("MangaSearchDatasource -> Failed to save database")
      } else {
        print("MangaSearchDatasource -> Saved database successfully")
      }
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
  ) {
    for manga in mangas {
      if mangaCrud.createOrUpdateManga(
        id: manga.id,
        title: manga.title,
        about: manga.description,
        status: manga.status,
        moc: moc
      ) == nil {
        print ("MangaSearchDatasource Error -> Error creating entity")
      }
    }
  }

}

// MARK: Search
extension MangaSearchDatasource {

  private func makeSearchRequest(
    _ searchValue: String,
    limit: Int,
    offset: Int
  ) async -> [MangaModel] {
    let data: [String: Any] = await restRequester.makeGetRequest(
      url: "https://api.mangadex.org/manga",
      parameters: [
        "title": searchValue,
        "includes[]": "cover_art",
        "limit": limit,
        "offset": offset
      ]
    )

    guard let dataJson = data["data"] as? [[String: Any]] else {
      print("MangaSearchDatasource -> Error getting json data")

      return []
    }

    let parsedData = mangaParser.parseMangaSearchResponse(dataJson)

    return await withTaskGroup(of: MangaModel.self, returning: [MangaModel].self) { taskGroup in
      for data in parsedData {
        taskGroup.addTask {
          let cover = await self.getCover(for: data.id, fileName: data.coverFileName)

          return data.convertToModel(cover: cover)
        }
      }

      return await taskGroup.reduce(into: [MangaModel]()) { partialResult, manga in
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
  ) async -> UIImage? {
    if let localCoverData = self.mangaCrud.getMangaCover(id, moc: viewMoc) {
      return UIImage(data: localCoverData)
    }

    if let remoteCoverData = await makeCoverRequest(id: id, coverFileName: fileName) {
      return UIImage(data: remoteCoverData)
    }

    return nil
  }

  private func makeCoverRequest(
    id: String,
    coverFileName: String
  ) async -> Data? {
    let coverData: Data? = await restRequester.makeGetRequest(
      url: "https://uploads.mangadex.org/covers/\(id)/\(coverFileName).256.jpg"
    )

    return coverData
  }

}
