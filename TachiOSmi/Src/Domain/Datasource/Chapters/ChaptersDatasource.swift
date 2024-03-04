//
//  ChaptersDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine
import CoreData

final class ChaptersDatasource {

  private let mangaId: String

  private let delegate: ChaptersDelegateType
  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let systemDateTime: SystemDateTimeType
  private let viewMoc: NSManagedObjectContext

  private let chapters: CurrentValueSubject<[ChapterModel], Never>
  private let count: CurrentValueSubject<Int, Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var chaptersPublisher: AnyPublisher<[ChapterModel], Never> {
    chapters.eraseToAnyPublisher()
  }

  var countPublisher: AnyPublisher<Int, Never> {
    count.eraseToAnyPublisher()
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

  @MainActor private var hasMorePages = true
  @MainActor private var currentPage = 0
  @MainActor private var results = [ChapterModel]() {
    didSet { count.valueOnMain = results.count }
  }

  private var fetchTask: Task<Void, Never>?

  let sortByNumber: (ChapterModel, ChapterModel) -> Bool = {
    guard
      let lhs = $0.number,
      let rhs = $01.number
    else {
      return $0.publishAt > $1.publishAt
    }

    return lhs > rhs
  }

  init(
    mangaId: String,
    delegate: ChaptersDelegateType,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    systemDateTime: SystemDateTimeType,
    viewMoc: NSManagedObjectContext
  ) {
    self.mangaId = mangaId
    self.delegate = delegate
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.systemDateTime = systemDateTime
    self.viewMoc = viewMoc

    chapters = CurrentValueSubject([])
    count = CurrentValueSubject(0)
    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func setupData() async {
    if let fetchTask {
      fetchTask.cancel()

      await fetchTask.value
    }

    await MainActor.run {
      state.valueOnMain = .loading
      chapters.valueOnMain = []
      error.valueOnMain = nil
      hasMorePages = true
      currentPage = 0
      results = []
    }

    fetchTask = Task { [weak self] in
      guard let self else { return }

      var results = [ChapterModel]()
      var erro: DatasourceError?

      do {
        results = try await self.fetchLocalChapters()

        if results.isEmpty {
          results = try await self.delegate.fetchChapters(mangaId: mangaId).map { $0.converToModel() }

          if results.isEmpty {
            await MainActor.run { self.hasMorePages = false }

            throw DatasourceError.otherError("No chapters found")
          }
        }

        await self.updateResultsAndSend(results)

        let newResults = try await self.fetchChaptersIfNeeded()

        if !newResults.isEmpty {
          await MainActor.run { [newResults] in
            self.results = newResults
            self.sendAllLoadedChapters()
          }

          try await self.updateDatabase(
            chapters: newResults,
            updatedAt: self.systemDateTime.now
          )
        }
      } catch {
        erro = .catchError(error)
      }

      await MainActor.run { [erro] in
        self.state.valueOnMain = .normal
        self.error.valueOnMain = erro
        self.fetchTask = nil
      }
    }
  }

  func refresh() async {
    if let fetchTask {
      fetchTask.cancel()

      await fetchTask.value
    }

    await MainActor.run {
      state.valueOnMain = .loading
      error.valueOnMain = nil
    }

    fetchTask = Task { [weak self] in
      guard let self else { return }

      var results = [ChapterModel]()
      var erro: DatasourceError?

      do {
        results = try await self.delegate.fetchChapters(mangaId: mangaId).map { $0.converToModel() }

        await MainActor.run { [results] in
          self.results = results
          self.sendAllLoadedChapters()
        }

        try await self.updateDatabase(
          chapters: results,
          updatedAt: self.systemDateTime.now
        )
      } catch {
        erro = .catchError(error)
      }

      await MainActor.run { [erro] in
        self.state.valueOnMain = .normal
        self.error.valueOnMain = erro
        self.fetchTask = nil
      }
    }
  }

  func loadNextPage() async {
    if await hasMorePages {
      await MainActor.run {
        sendNextChapters()
      }
    }
  }

  private func fetchChaptersIfNeeded() async throws -> [ChapterModel] {
    let manga = try viewMoc.performAndWait {
      try mangaCrud.getManga(mangaId, moc: viewMoc)
    }

    guard let manga else {
      throw CrudError.mangaNotFound(id: mangaId)
    }

    guard let lastUpdateAt = manga.lastUpdateAt else {
      return try await delegate.fetchChapters(mangaId: mangaId).map { $0.converToModel() }
    }

    if systemDateTime.comparator.isDate(
      lastUpdateAt,
      lessThanOrEqual: systemDateTime.calculator.removeDays(5, to: systemDateTime.now)
    ) {
      return try await delegate.fetchChapters(mangaId: mangaId).map { $0.converToModel() }
    }

    return []
  }

  private func fetchLocalChapters() async throws -> [ChapterModel] {
    return try chapterCrud
      .getAllChapters(mangaId: mangaId, moc: viewMoc)
      .map { ChapterModel.from($0) }
      .sorted(by: sortByNumber)
  }

}

// MARK: MainActor
extension ChaptersDatasource {

  @MainActor
  private func updateResultsAndSend(
    _ results: [ChapterModel]
  ) {
    self.results = results

    sendNextChapters()
  }

  @MainActor
  private func sendNextChapters() {
    let limit = 30
    let i = currentPage * limit
    let j = min(i + limit, results.count)

    if i > j {
      hasMorePages = false

      return
    }

    chapters.valueOnMain.append(contentsOf: results[i..<j])

    currentPage += 1
  }

  @MainActor
  func sendAllLoadedChapters() {
    let limit = 30
    let i = min(currentPage * limit, results.count)

    hasMorePages = i < results.count

    chapters.valueOnMain = Array(results[0..<i])
  }

}

// MARK: Database
extension ChaptersDatasource {

  private func updateDatabase(
    chapters: [ChapterModel],
    updatedAt: Date
  ) async throws {
    try await viewMoc.perform {
      guard let manga = try self.mangaCrud.getManga(self.mangaId, moc: self.viewMoc) else {
        throw CrudError.mangaNotFound(id: self.mangaId)
      }

      for chapter in chapters {
        _ = try self.chapterCrud.createOrUpdateChapter(
          id: chapter.id,
          chapterNumber: chapter.number,
          title: chapter.title,
          numberOfPages: chapter.numberOfPages,
          publishAt: chapter.publishAt,
          urlInfo: chapter.downloadInfo,
          manga: manga,
          moc: self.viewMoc
        )
      }

      self.mangaCrud.updateLastUpdateAt(manga, date: updatedAt)

      if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
    }
  }

}

