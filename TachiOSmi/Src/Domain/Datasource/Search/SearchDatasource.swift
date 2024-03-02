//
//  SearchDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine
import CoreData

final class SearchDatasource<Source: SourceType> {

  private let delegate: Source.SearchDelegate
  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let viewMoc: NSManagedObjectContext

  private let mangas: CurrentValueSubject<[MangaSearchResult], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  @MainActor var hasMorePages = true
  @MainActor private var currentPage = 0

  var mangasPublisher: AnyPublisher<[MangaSearchResult], Never> {
    mangas.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  private var fetchTask: Task<Void, Never>?

  init(
    delegate: Source.SearchDelegate,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    viewMoc: NSManagedObjectContext = Source.database.viewMoc
  ) {
    self.delegate = delegate
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.viewMoc = viewMoc

    mangas = CurrentValueSubject([])
    state  = CurrentValueSubject(.starting)
    error  = CurrentValueSubject(nil)
  }

  func searchManga(
    _ search: MangaSearchType
  ) async {
    if let fetchTask {
      fetchTask.cancel()

      await fetchTask.value
    }

    await MainActor.run {
      state.valueOnMain = .loading
      mangas.valueOnMain = []
      error.valueOnMain = nil
      hasMorePages = true
      currentPage = 0
    }

    fetchTask = Task { [weak self] in
      print("MangaSearchDatasource -> Search task started")

      guard let self else { return }

      var erro: DatasourceError?

      do {
        let results = try await self.fetchSearchResults(search, page: 0)

        let mangas = results.map {
          MangaSearchResult(
            id: $0.id,
            title: $0.title,
            cover: nil
          )
        }

        await MainActor.run { self.mangas.valueOnMain = mangas }

        doFetchCoversTask(results)
      } catch {
        erro = self.catchError(error)
      }

      await MainActor.run { [erro] in
        self.state.valueOnMain = .normal
        self.error.valueOnMain = erro
        self.fetchTask = nil
      }

      print("MangaSearchDatasource -> Search task ended")
    }
  }

  func loadNextPage(
    _ search: MangaSearchType
  ) async {
    if let fetchTask {
      await fetchTask.value
    }

    let page = await MainActor.run(resultType: Int.self) {
      self.error.valueOnMain = nil
      self.currentPage += 1

      return currentPage
    }

    fetchTask = Task { [weak self] in
      guard let self else { return }
      print("MangaSearchDatasource -> Loading page \(page)")

      var erro: DatasourceError?

      do {
        let results = try await self.fetchSearchResults(search, page: page)

        if results.isEmpty {
          await MainActor.run { self.hasMorePages = false }

          return
        }

        await appendResults(results.map {
          MangaSearchResult(
            id: $0.id,
            title: $0.title,
            cover: nil
          )
        })

        doFetchCoversTask(results)
      } catch {
        erro = self.catchError(error)
      }

      await MainActor.run { [erro] in
        self.error.valueOnMain = erro
        self.fetchTask = nil
      }

      print("MangaSearchDatasource -> Finished loading page \(page)")
    }
  }

  private func fetchSearchResults(
    _ search: MangaSearchType,
    page: Int
  ) async throws -> [MangaParsedData] {
    switch search {
    case .query(let value):
      return try await self.delegate.fetchSearchResults(value, page: page)

    case .trending:
      return try await self.delegate.fetchTrending(page: page)
    }
  }

  private func doFetchCoversTask(
    _ results: [MangaParsedData]
  ) {
    Task(priority: .background) {
      let info = await self.fetchCovers(for: results)

      try await self.storeCovers(info)
    }
  }

  private func fetchCovers(
    for mangas: [MangaParsedData]
  ) async -> [(String, Data?)] {
    await withTaskGroup(of: (String, Data?).self, returning: [(String, Data?)].self) { taskGroup in
      for data in mangas {
        taskGroup.addTask {
          let id = data.id

          let cover = await self.fetchCover(
            mangaId: id,
            fileName: data.coverInfo
          )

          await self.updateCover(id, cover: cover)

          return (id, cover)
        }
      }

      return await taskGroup.reduce(into: [(String, Data?)]()) { partialResult, cover in
        partialResult.append(cover)
      }
    }
  }

  func fetchCover(
    mangaId: String,
    fileName: String
  ) async -> Data? {
    do {
      let localCoverData = try viewMoc.performAndWait {
        try coverCrud.getCoverData(for: mangaId, moc: viewMoc)
      }

      if let localCoverData {
        return localCoverData
      }

      let remoteCoverData = try await delegate.fetchCover(id: mangaId, fileName: fileName)

      return remoteCoverData
    } catch {
      if let erro = catchError(error) {
        print("MangaSearchDelegate -> Error: \(erro.localizedDescription)")
      }
    }

    return nil
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
  private func updateCovers(
    using info: [(String, Data?)]
  ) {
    info.forEach { updateCover($0.0, cover: $0.1) }
  }

  @MainActor
  private func updateCover(
    _ id: String,
    cover: Data?
  ) {
    guard let cover else { return }

    if let i = mangas.valueOnMain.firstIndex(where: { $0.id == id }) {
      let manga = mangas.valueOnMain[i]

      mangas.valueOnMain[i] = MangaSearchResult(
        id: manga.id,
        title: manga.title,
        cover: cover
      )
    }
  }

  @MainActor func appendResults(
    _ mangas: [MangaSearchResult]
  ) {
    self.mangas.valueOnMain.append(contentsOf: mangas)
  }

}

// MARK: Database
extension SearchDatasource {

  private func storeCovers(
    _ coverInfo: [(String, Data?)]
  ) async throws {
    try await viewMoc.perform {
      for (id, data) in coverInfo {
        guard let data else { continue }

        _ = try self.coverCrud.createOrUpdateEntity(
          mangaId: id,
          data: data,
          moc: self.viewMoc
        )
      }

      if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
    }
  }

}

