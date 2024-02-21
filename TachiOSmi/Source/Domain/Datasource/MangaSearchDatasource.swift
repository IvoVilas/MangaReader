//
//  MangaSearchDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import Combine
import CoreData

final class MangaSearchDatasource {

  private let mangaParser: MangaParser
  private let mangaCrud: MangaCrud
  private let moc: NSManagedObjectContext

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

  private var fetchTask: Task<Void, any Error>?

  init(
    mangaParser: MangaParser,
    mangaCrud: MangaCrud,
    moc: NSManagedObjectContext
  ) {
    self.mangaParser = mangaParser
    self.mangaCrud   = mangaCrud
    self.moc         = moc

    mangas = CurrentValueSubject([])
    state  = CurrentValueSubject(.starting)

    setupInitalValues()
  }

  func setupInitalValues() {
    mangas.value = mangaCrud
      .getAllMangasWithChapters(moc: moc)
      .map { .from($0) }

    state.value = .normal
  }

  func refresh(
    _ searchValue: String
  ) async {
    if let fetchTask {
      fetchTask.cancel()

      try? await fetchTask.value
    }

    state.value = .loading

    fetchTask = Task { [weak self] in
      guard let self else {
        self?.fetchTask   = nil
        self?.state.value = .normal

        return
      }

      do {
        try Task.checkCancellation()

        print("MangaSearchDatasource -> Fetch task intiated")

        self.mangas.value = []

        try await self.makeSearchRequest(searchValue)

        self.state.value = .normal

        print("MangaSearchDatasource -> Fetch task ended")
      } catch {
        self.state.value = .cancelled

        print("MangaSearchDatasource -> Fetch task cancelled")
      }

      self.fetchTask = nil
    }
  }

  private func makeSearchRequest(
    _ searchValue: String
  ) async throws{
    var results = [MangaParser.MangaParsedData]()
    let limit   = 10
    var offset  = 0

    // TODO: Implement user pagination
    // TODO: Implement taskGroup
    while true && offset < 30 {
      try Task.checkCancellation()

      let result = try await makeSearchRequest(
        searchValue,
        limit: limit,
        offset: offset
      )

      if result.isEmpty { break }

      results.append(contentsOf: result)
      offset += limit

      mangas.value.append(
        contentsOf: result.map {
          $0.toModel(mangaCrud.getManga($0.id, moc: moc)?.coverArt)
        }
      )
    }

    try Task.checkCancellation()

    print("MangaSearchDatasource -> Starting to fetch missing covers")

    let needCovers = Set(
      mangas.value
        .filter { $0.cover == nil }
        .map { $0.id }
    )

    let shouldFetchCover = results.filter { needCovers.contains($0.id) }
    let updatedCovers    = try await makeCoversRequest(mangas: shouldFetchCover)
    var updatedMangas    = [MangaModel]()

    for manga in mangas.value {
      if let updated = updatedCovers.first(where: { $0.id == manga.id }) {
        updatedMangas.append(updated)
      } else {
        updatedMangas.append(manga)
      }
    }

    print("MangaSearchDatasource -> Fetched \(updatedCovers.count) covers from \(updatedMangas.count) mangas")

    self.mangas.value = updatedMangas
  }

  private func makeSearchRequest(
    _ searchValue: String,
    limit: Int,
    offset: Int
  ) async throws -> [MangaParser.MangaParsedData] {
    let urlString = "https://api.mangadex.org/manga"

    let parameters: [String: Any] = [
      "title": searchValue,
      "includes[]": "cover_art",
      "limit": limit,
      "offset": offset
    ]

    var urlParameters = URLComponents(string: urlString)
    urlParameters?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

    guard let url = urlParameters?.url else {
      print ("MangaSearchDatasource -> Error creating url")

      return []
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      try Task.checkCancellation()

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let response = response as? HTTPURLResponse else {
        print("MangaSearchDatasource -> Response parse error")

        return []
      }

      guard response.statusCode == 200 else {
        print("MangaSearchDatasource -> Received response with code \(response.statusCode)")

        return []
      }

      guard
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let dataJson = json["data"] as? [[String: Any]]
      else {
        print("MangaSearchDatasource -> Error creating response json")

        return []
      }

      try Task.checkCancellation()

      let parsedData = mangaParser.parseMangaSearchResponse(dataJson)

      for manga in parsedData {
        if mangaCrud.createOrUpdateManga(
          id: manga.id,
          title: manga.title,
          about: manga.description,
          status: manga.status,
          moc: moc
        ) == nil {
          print("MangaSearchDatasource -> Error creating entities")
        }
      }

      _ = moc.saveIfNeeded(rollbackOnError: true)

      return parsedData
    } catch {
      if let cancellationError = error as? CancellationError {
        throw cancellationError
      } else {
        print("MangaSearchDatasource -> Error during request \(error)")
      }
    }

    return []
  }

  private func makeCoversRequest(
    mangas: [MangaParser.MangaParsedData]
  ) async throws -> Set<MangaModel> {
    return try await withThrowingTaskGroup(of: MangaModel?.self, returning: Set<MangaModel>.self) { taskGroup in
      for manga in mangas {
        taskGroup.addTask {
          try await self.makeCoverRequest(mangaId: manga.id, coverFileName: manga.coverFileName)
        }
      }

      return try await taskGroup.reduce(into: Set<MangaModel>()) { partialResult, manga in
        if let manga {
          partialResult.insert(manga)
        }
      }
    }
  }

  private func makeCoverRequest(
    mangaId: String,
    coverFileName: String
  ) async throws -> MangaModel? {
    let urlString = "https://uploads.mangadex.org/covers/\(mangaId)/\(coverFileName).256.jpg"

    guard let url = URL(string: urlString) else {
      print ("MangaSearchDatasource -> Error creating url")

      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      try Task.checkCancellation()

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let response = response as? HTTPURLResponse else {
        print("MangaSearchDatasource -> Response parse error")

        return nil
      }

      guard response.statusCode == 200 else {
        print("MangaSearchDatasource -> Received response with code \(response.statusCode)")

        return nil
      }

      guard let manga = mangaCrud.getManga(mangaId, moc: moc) else {
        print("MangaParser Error -> Manga not found \(mangaId)")

        return nil
      }

      mangaCrud.updateCoverArt(manga, data: data)

      _ = moc.saveIfNeeded(rollbackOnError: true)

      return MangaModel.from(
        manga,
        coverData: data
      )
    } catch {
      if let cancellationError = error as? CancellationError {
        throw cancellationError
      } else {
        print("MangaSearchDatasource -> Error during request \(error)")
      }
    }

    return nil
  }

}
