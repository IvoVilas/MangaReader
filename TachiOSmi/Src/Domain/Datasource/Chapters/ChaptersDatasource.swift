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
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var chaptersPublisher: AnyPublisher<[ChapterModel], Never> {
    chapters.eraseToAnyPublisher()
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
    }

    fetchTask = Task { [weak self] in
      guard let self else { return }

      var results = [ChapterModel]()
      var erro: DatasourceError?

      do {
        results = try await self.fetchLocalChapters()

        self.chapters.value = results

        let newResults = try await self.fetchChaptersIfNeeded()

        if !newResults.isEmpty {
          self.chapters.value = newResults

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
        let remote = try await self.delegate.fetchChapters(mangaId: mangaId)

        results = await mapWithLocalData(remote)

        self.chapters.value = results

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

  private func fetchChaptersIfNeeded() async throws -> [ChapterModel] {
    let manga = try await viewMoc.perform {
      try self.mangaCrud.getManga(self.mangaId, moc: self.viewMoc)
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
  }

  private func mapWithLocalData(
    _ chapters: [ChapterIndexResult]
  ) async -> [ChapterModel] {
    await viewMoc.perform {
      var res = [ChapterModel]()

      for chapter in chapters {
        let local = try? self.chapterCrud.getChapter(chapter.id, moc: self.viewMoc)

        if let local {
          res.append(chapter.converToModel(isRead: local.isRead, lastPageRead: local.lastPageRead?.intValue))
        } else {
          res.append(chapter.converToModel())
        }
      }

      return res
    }
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

