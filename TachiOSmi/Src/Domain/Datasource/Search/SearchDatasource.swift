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

        let updatedInfo = await self.fetchCovers(
          for: results,
          viewMoc: viewMoc
        )

        await self.addCoversTo(updatedInfo)
        try await self.storeCovers(updatedInfo)
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

        let mangas = results.map { $0.convertToModel() }
        await appendResults(mangas)

        let updatedInfo = await self.fetchCovers(
          for: results,
          viewMoc: viewMoc
        )

        await self.addCoversTo(updatedInfo)
        try await self.storeCovers(updatedInfo)
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

  @MainActor
  private func addCoversTo(
    _ info: [(String, Data?)]
  ) {
    info.forEach { addCoverTo($0.0, cover: $0.1) }
  }

  @MainActor
  private func addCoverTo(
    _ id: String,
    cover: Data?
  ) {
    if let i = mangas.valueOnMain.firstIndex(where: { $0.id == id }) {
      mangas.valueOnMain[i].cover = cover
    }
  }

  @MainActor func appendResults(
    _ mangas: [MangaModel]
  ) {
    self.mangas.valueOnMain.append(contentsOf: mangas)
  }

  // TODO: Emit one cover at a time instead waiting for all
  func fetchCovers(
    for mangas: [MangaParser.MangaParsedData],
    viewMoc: NSManagedObjectContext
  ) async -> [(String, Data?)] {
    await withTaskGroup(of: (String, Data?).self, returning: [(String, Data?)].self) { taskGroup in
      for data in mangas {
        taskGroup.addTask {
          let id = data.id

          let cover = await self.fetchCover(
            mangaId: id,
            fileName: data.coverFileName,
            viewMoc: viewMoc
          )

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
    fileName: String,
    viewMoc: NSManagedObjectContext
  ) async -> Data? {
    do {
      if let localCoverData = try coverCrud.getCoverData(for: mangaId, moc: viewMoc) {
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

