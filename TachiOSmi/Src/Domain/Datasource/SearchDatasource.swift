//
//  SearchDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine
import CoreData

final class SearchDatasource {

  let source: Source
  private let delegate: SearchDelegateType
  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let moc: NSManagedObjectContext

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
    source: Source,
    delegate: SearchDelegateType,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    moc: NSManagedObjectContext
  ) {
    self.source = source
    self.delegate = delegate
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.moc = moc

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
      guard let self else { return }

      print("MangaSearchDatasource -> Starting search task for \(self.source.name)...")

      var erro: DatasourceError?

      do {
        let results = try await self.fetchSearchResults(search, page: 0)
        let pageSize: Int

        switch search {
        case .trending: pageSize = delegate.trendingPageSize
        case .query: pageSize = delegate.searchPageSize
        }

        let mangas = results.map {
          MangaSearchResult(
            id: $0.id,
            title: $0.title,
            cover: nil,
            source: self.source
          )
        }

        await MainActor.run { [mangas] in
          self.mangas.valueOnMain = mangas
          self.hasMorePages = results.count >= pageSize
        }

        doFetchCoversTask(results)
      } catch {
        erro = .catchError(error)
      }

      await MainActor.run { [erro] in
        self.state.valueOnMain = .normal
        self.error.valueOnMain = erro
        self.fetchTask = nil
      }

      print("MangaSearchDatasource -> Ended search task for \(self.source.name)")
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
        let pageSize: Int

        switch search {
        case .trending: pageSize = delegate.trendingPageSize
        case .query: pageSize = delegate.searchPageSize
        }

        if results.count < pageSize {
          await MainActor.run { self.hasMorePages = false }

          return
        }

        let mangas = results.map {
          MangaSearchResult(
            id: $0.id,
            title: $0.title,
            cover: nil,
            source: self.source
          )
        }

        await appendResults(mangas)

        doFetchCoversTask(results)
      } catch {
        erro = .catchError(error)
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
  ) async throws -> [MangaSearchResultParsedData] {
    switch search {
    case .query(let value):
      return try await self.delegate.fetchSearchResults(value, page: page)

    case .trending:
      return try await self.delegate.fetchTrending(page: page)
    }
  }

  private func doFetchCoversTask(
    _ results: [MangaSearchResultParsedData]
  ) {
    Task(priority: .background) {
      let info = await self.fetchCovers(for: results)

      try await self.storeCovers(info)
    }
  }

  private func fetchCovers(
    for mangas: [MangaSearchResultParsedData]
  ) async -> [(String, Data?)] {
    await withTaskGroup(of: (String, Data?).self, returning: [(String, Data?)].self) { taskGroup in
      for data in mangas {
        taskGroup.addTask {
          let id = data.id

          let cover = await self.fetchCover(
            mangaId: id,
            downloadInfo: data.coverDownloadInfo
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
    downloadInfo: String
  ) async -> Data? {
    do {
      let localCoverData = try await moc.perform {
        try self.coverCrud.getCoverData(for: mangaId, moc: self.moc)
      }

      if let localCoverData {
        return localCoverData
      }

      let remoteCoverData = try await delegate.fetchCover(
        mangaId: mangaId,
        coverInfo: downloadInfo
      )

      return remoteCoverData
    } catch {
      if let erro = DatasourceError.catchError(error) {
        print("MangaSearchDelegate -> Error: \(erro.localizedDescription)")
      }
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
        cover: cover,
        source: source
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
    try await moc.perform {
      for (id, data) in coverInfo {
        guard let data else { continue }

        _ = try self.coverCrud.createOrUpdateEntity(
          mangaId: id,
          data: data,
          moc: self.moc
        )
      }

      _ = try self.moc.saveIfNeeded()
    }
  }

}

