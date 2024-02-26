//
//  MangaChapterDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 19/02/2024.
//

import Foundation
import Combine
import CoreData

final class MangaChapterDatasource {

  private let mangaId: String

  private let httpClient: HttpClient
  private let chapterParser: ChapterParser
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

  private static let sortByNumber: (ChapterModel, ChapterModel) -> Bool = {
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
    httpClient: HttpClient,
    chapterParser: ChapterParser,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    systemDateTime: SystemDateTimeType,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    self.mangaId        = mangaId
    self.httpClient     = httpClient
    self.chapterParser  = chapterParser
    self.mangaCrud      = mangaCrud
    self.chapterCrud    = chapterCrud
    self.systemDateTime = systemDateTime
    self.viewMoc        = viewMoc

    chapters = CurrentValueSubject([])
    state    = CurrentValueSubject(.starting)
    error    = CurrentValueSubject(nil)
  }

  func refresh(
    isForceRefresh: Bool = false
  ) async {
    if let fetchTask {
      fetchTask.cancel()

      await fetchTask.value
    }

    state.value    = .loading
    chapters.value = []
    error.value    = nil

    fetchTask = Task { [weak self] in
      print("MangaChapterDatasource -> Started chapter fetch task")
      guard let self else { return }

      do {
        self.chapters.value = try await self.fetchLocalChapters()

        if isForceRefresh {
          try await self.chapterRefresh()
        } else {
          try await self.chapterRefreshIfNeeded()
        }
      } catch is CancellationError {
        print("MangaChapterDatasource -> Fetch task cancelled")
      } catch let error as ParserError {
        self.error.value = .errorParsingResponse(error.localizedDescription)
      } catch let error as HttpError {
        self.error.value = .networkError(error.localizedDescription)
      } catch let error as CrudError {
        self.error.value = .databaseError(error.localizedDescription)
      } catch {
        self.error.value = .unexpectedError(error.localizedDescription)
      }

      self.state.value = .normal
      self.fetchTask   = nil

      print("MangaChapterDatasource -> Ended chapter fetch task")
    }
  }

  private func fetchLocalChapters() async throws -> [ChapterModel] {
    return try chapterCrud
      .getAllChapters(mangaId: mangaId, moc: viewMoc)
      .map { ChapterModel.from($0) }
      .sorted(by: MangaChapterDatasource.sortByNumber)
  }

  private func chapterRefreshIfNeeded() async throws {
    try Task.checkCancellation()

    guard let manga = try mangaCrud.getManga(mangaId, moc: viewMoc) else {
      throw CrudError.mangaNotFound(id: mangaId)
    }

    guard let lastUpdateAt = manga.lastUpdateAt else {
      try await chapterRefresh()

      return
    }

    if systemDateTime.comparator.isDate(
      lastUpdateAt,
      lessThanOrEqual: systemDateTime.calculator.removeDays(5, to: systemDateTime.now)
    ) {
      try await chapterRefresh()
    }
  }

  private func chapterRefresh() async throws {
    print("MangaChapterDatasource -> Fetch task started")
    try Task.checkCancellation()

    let results = try await fetchChapters()

    chapters.value = results

    try await PersistenceController.shared.container.performBackgroundTask { moc in
      try self.updateDatabase(
        chapters: results,
        updatedAt: Date(),
        moc: moc
      )
    }

    print("MangaChapterDatasource -> Fetch task ended")
  }

  private func fetchChapters() async throws -> [ChapterModel] {
    print("MangaChapterDatasource -> Fetch task intiated")

    var results = [ChapterModel]()
    let limit   = 25
    var offset  = 0

    while true {
      try Task.checkCancellation()

      let result = try await makeChapterFeedRequest(limit: limit, offset: offset)

      if result.isEmpty { break }

      offset += limit

      results.append(contentsOf: result)
    }

    return results
  }

  private func updateDatabase(
    chapters: [ChapterModel],
    updatedAt: Date,
    moc: NSManagedObjectContext
  ) throws {
    guard let manga = try mangaCrud.getManga(mangaId, moc: moc) else {
      throw CrudError.mangaNotFound(id: mangaId)
    }

    for chapter in chapters {
      _ = try chapterCrud.createOrUpdateChapter(
        id: chapter.id,
        chapterNumber: chapter.number,
        title: chapter.title,
        numberOfPages: chapter.numberOfPages,
        publishAt: chapter.publishAt,
        manga: manga,
        moc: moc
      )
    }

    mangaCrud.updateLastUpdateAt(manga, date: updatedAt)

    if !moc.saveIfNeeded(rollbackOnError: true).isSuccess {
      throw CrudError.saveError
    }
  }

}

extension MangaChapterDatasource {

  private func makeChapterFeedRequest(
    limit: Int,
    offset: Int
  ) async throws -> [ChapterModel] {
    let json = try await httpClient.makeJsonGetRequest(
      url: "https://api.mangadex.org/manga/\(mangaId)/feed",
      parameters: [
        ("translatedLanguage[]", "en"),
        ("order[chapter]", "desc"),
        ("order[createdAt]", "desc"),
        ("limit", limit),
        ("offset", offset)
      ]
    )

    guard let dataJson = json["data"] as? [[String: Any]] else {
      throw ParserError.parameterNotFound("data")
    }

    return chapterParser.parseChapterData(mangaId: mangaId, data: dataJson)
  }

}
