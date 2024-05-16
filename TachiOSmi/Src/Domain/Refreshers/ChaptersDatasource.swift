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
  private let moc: NSManagedObjectContext

  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

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
    moc: NSManagedObjectContext
  ) {
    self.mangaId = mangaId
    self.delegate = delegate
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.systemDateTime = systemDateTime
    self.moc = moc

    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func refresh(
    force: Bool = false
  ) async {
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

      var results = [ChapterIndexResult]()
      var erro: DatasourceError?

      do {
        if try await needsFetch(isForce: force) {
          print("MangaDetailsDatasource -> Starting manga chapters refresh...")

          results = try await self.delegate.fetchChapters(mangaId: mangaId)

          try await self.updateDatabase(
            chapters: results,
            updatedAt: self.systemDateTime.now
          )

          print("MangaDetailsDatasource -> Ended manga chapters refresh")
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

  private func needsFetch(isForce: Bool) async throws -> Bool {
    if isForce {
      return true
    }

    let context = moc
    var nedsFetch = false

    try await context.perform {
      guard
        let manga = try self.mangaCrud.getManga(self.mangaId, moc: context)
      else {
        return
      }

      nedsFetch = !self.updatedRecently(manga.lastUpdateAt)
    }

    return nedsFetch
  }

  private func updatedRecently(_ date: Date?) -> Bool {
    guard let date else {
      return false
    }

    let fiveDaysAgo = systemDateTime.calculator.removeDays(5, to: systemDateTime.now)

    return systemDateTime.comparator.isDate(fiveDaysAgo, lessThanOrEqual: date)
  }

}

// MARK: Database
extension ChaptersDatasource {

  private func updateDatabase(
    chapters: [ChapterIndexResult],
    updatedAt: Date
  ) async throws {
    let context = moc

    try await context.perform {
      guard let manga = try self.mangaCrud.getManga(self.mangaId, moc: context) else {
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
          moc: context
        )
      }

      self.mangaCrud.updateLastUpdateAt(manga, date: updatedAt)

      if !context.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
    }
  }

}

