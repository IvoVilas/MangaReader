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

  private let delegate: SearchDelegateType
  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let viewMoc: NSManagedObjectContext

  private let mangas: CurrentValueSubject<[MangaModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  @MainActor var hasMorePages = true
  @MainActor private var currentPage = 0

  var mangasPublisher: AnyPublisher<[MangaModel], Never> {
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
    delegate: SearchDelegateType,
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
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
    _ searchValue: String
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
        let results = try await self.delegate.fetchSearchResults(searchValue, page: 0)
        let mangas = results.map { $0.convertToModel() }

        await MainActor.run { self.mangas.valueOnMain = mangas }

        doFetchCoversTask(results)
      } catch {
        erro = self.delegate.catchError(error)
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
    _ searchValue: String
  ) async {
    if let fetchTask {
      await fetchTask.value
    }

    let page = await MainActor.run(resultType: Int.self) {
      let page = self.currentPage

      self.error.valueOnMain = nil
      self.currentPage += 1

      return page
    }

    fetchTask = Task { [weak self] in
      guard let self else { return }
      print("MangaSearchDatasource -> Loading page \(page)")

      var erro: DatasourceError?

      do {
        let results = try await self.delegate.fetchSearchResults(
          searchValue,
          page: currentPage
        )

        if results.isEmpty {
          await MainActor.run { self.hasMorePages = false }

          return
        }

        await appendResults(results.map { $0.convertToModel() })

        doFetchCoversTask(results)
      } catch {
        erro = self.delegate.catchError(error)
      }

      await MainActor.run { [erro] in
        self.error.valueOnMain = erro
        self.fetchTask = nil
      }

      print("MangaSearchDatasource -> Finished loading page \(page)")
    }
  }

  private func doFetchCoversTask(
    _ results: [MangaParser.MangaParsedData]
  ) {
    Task(priority: .background) {
      let info = await self.fetchCovers(for: results)

      try await self.storeCovers(info)
    }
  }

  private func fetchCovers(
    for mangas: [MangaParser.MangaParsedData]
  ) async -> [(String, Data?)] {
    await withTaskGroup(of: (String, Data?).self, returning: [(String, Data?)].self) { taskGroup in
      for data in mangas {
        taskGroup.addTask {
          let id = data.id

          let cover = await self.fetchCover(
            mangaId: id,
            fileName: data.coverFileName
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
      if let erro = delegate.catchError(error) {
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

      mangas.valueOnMain[i] = MangaModel(
        id: manga.id,
        title: manga.title,
        description: manga.description,
        status: manga.status,
        cover: cover,
        tags: manga.tags,
        authors: manga.authors
      )
    }
  }

  @MainActor func appendResults(
    _ mangas: [MangaModel]
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

