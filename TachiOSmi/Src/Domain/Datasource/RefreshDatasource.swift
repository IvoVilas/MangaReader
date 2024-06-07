//
//  RefreshDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation
import Combine
import CoreData

final class RefreshDatasource {

  private let manga: MangaSearchResult
  private let delegate: RefreshDelegateType
  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let coverCrud: CoverCrud
  private let authorCrud: AuthorCrud
  private let tagCrud: TagCrud
  private let appOptionsStore: AppOptionsStore
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

  private var fetchTask: Task<Void, Never>?

  init(
    manga: MangaSearchResult,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    coverCrud: CoverCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    appOptionsStore: AppOptionsStore,
    systemDateTime: SystemDateTimeType,
    httpClient: HttpClientType,
    moc: NSManagedObjectContext
  ) {
    self.manga = manga
    self.delegate = manga.source.refreshDelegateType.init(httpClient: httpClient)
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.coverCrud = coverCrud
    self.authorCrud = authorCrud
    self.tagCrud = tagCrud
    self.appOptionsStore = appOptionsStore
    self.systemDateTime = systemDateTime
    self.moc = moc

    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func refresh(
    force: Bool = false
  ) async {
    if fetchTask != nil {
      return
    }

    fetchTask = Task { [weak self] in
      guard let self else { return }

      self.state.value = .loading
      self.error.value = nil

      do {
        if try await self.needsFetch(isForce: force) {
          print("MangaRefreshDatasource -> Starting manga details refresh...")

          let data = try await self.delegate.fetchRefreshData(self.manga.id, updateCover: force)

          try await self.updateDatabase(data, updatedAt: self.systemDateTime.now)

          print("MangaRefreshDatasources -> Ended manga details refresh")
        }
      } catch {
        self.error.value = .catchError(error)
      }

      self.state.value = .normal
      self.fetchTask = nil
    }

    _ = await fetchTask?.result
  }

  private func needsFetch(isForce: Bool) async throws -> Bool {
    if isForce {
      return true
    }

    let context = moc
    
    return try await context.perform {
      guard let manga = try self.mangaCrud.getManga(self.manga.id, moc: context) else {
        return true
      }

      return !self.updatedRecently(manga.lastUpdateAt)
    }
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
extension RefreshDatasource {

  private func updateDatabase(
    _ data: MangaRefreshData,
    updatedAt: Date
  ) async throws {
    let context = moc

    try context.performAndWait {
      let manga = try self.mangaCrud.createOrUpdateManga(
        id: data.id,
        title: data.title,
        synopsis: data.description,
        isSaved: nil,
        status: data.status,
        source: self.manga.source,
        readingDirection: self.appOptionsStore.defaultDirection,
        moc: context
      )

      if let cover = data.cover ?? self.manga.cover {
        _ = try self.coverCrud.createOrUpdateEntity(
          mangaId: data.id,
          data: cover,
          moc: context
        )
      }

      // For now, we only store one author
      if let author = data.authors.first {
        _ = try self.authorCrud.createOrUpdateAuthor(
          id: author.id,
          name: author.name,
          manga: manga,
          moc: context
        )
      }

      for tag in data.tags {
        _ = try self.tagCrud.createOrUpdateTag(
          id: tag.id,
          title: tag.title,
          manga: manga,
          moc: context
        )
      }

      for chapter in data.chapters {
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

      _ = try context.saveIfNeeded()
    }
  }

}


