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

  private let restRequester: RestRequester
  private let chapterParser: ChapterParser
  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let systemDateTime: SystemDateTimeType
  private let viewMoc: NSManagedObjectContext

  private let chapters: CurrentValueSubject<[ChapterModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>

  var chaptersPublisher: AnyPublisher<[ChapterModel], Never> {
    chapters.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var stateValue: DatasourceState {
    state.value
  }

  private var fetchTask: Task<Void, any Error>?

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
    restRequester: RestRequester,
    chapterParser: ChapterParser,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    systemDateTime: SystemDateTimeType,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    self.mangaId        = mangaId
    self.restRequester  = restRequester
    self.chapterParser  = chapterParser
    self.mangaCrud      = mangaCrud
    self.chapterCrud    = chapterCrud
    self.systemDateTime = systemDateTime
    self.viewMoc        = viewMoc

    chapters = CurrentValueSubject([])
    state    = CurrentValueSubject(.starting)
  }

  func refresh(
    isForceRefresh: Bool = false
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

      let chapters = await Task.detached { () -> [ChapterModel] in
        await self.fetchLocalChapters()
      }.value

      self.chapters.value = chapters

      do {
        try Task.checkCancellation()

        if isForceRefresh {
          try await Task.detached {
            try await self.chapterRefresh()
          }.value
        } else {
          try await self.chapterRefreshIfNeeded()
        }

        self.state.value = .normal
      } catch {
        self.state.value = .cancelled

        print("MangaChapterDatasource -> Fetch task cancelled")
      }

      self.fetchTask = nil
    }
  }

  private func fetchLocalChapters() async -> [ChapterModel] {
    /// Maybe move to background?
    return await viewMoc.perform { [weak viewMoc] in
      guard let viewMoc else { return [] }

      return self.chapterCrud
        .getAllChapters(mangaId: self.mangaId, moc: viewMoc)
        .map { ChapterModel.from($0) }
        .sorted(by: MangaChapterDatasource.sortByNumber)
    }
  }

  private func chapterRefreshIfNeeded() async throws {
    guard let manga = mangaCrud.getManga(mangaId, moc: viewMoc) else {
      print("MangaChapterDatasource -> Manga not found \(mangaId)")

      return
    }

    if let lastUpdateAt = manga.lastUpdateAt {
      if systemDateTime.comparator.isDate(
        lastUpdateAt,
        lessThanOrEqual: systemDateTime.calculator.removeDays(5, to: systemDateTime.now)
      ) {
        try await Task.detached {
          try await self.chapterRefresh()
        }.value
      }
    } else {
      try await Task.detached {
        try await self.chapterRefresh()
      }.value
    }
  }

  private func chapterRefresh() async throws {
    print("MangaChapterDatasource -> Fetch task started")

    let results = try await fetchChapters()

    await PersistenceController.shared.container.performBackgroundTask { moc in
      print("MangaChapterDatabase -> Saving \(results.count) items into the database")

      self.updateDatabase(
        chapters: results,
        updatedAt: Date(),
        moc: moc
      )

      if !moc.saveIfNeeded(rollbackOnError: true).isSuccess {
        print("MangaChapterDatasource -> Failed to save database")
      } else {
        print("MangaChapterDatasource -> Saved database successfully")
      }
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

      let result = await makeChapterFeedRequest(limit: limit, offset: offset)

      if result.isEmpty { break }

      offset += limit

      results.append(contentsOf: result)
    }

    self.chapters.value = results.sorted(by: MangaChapterDatasource.sortByNumber)

    return results
  }

  private func updateDatabase(
    chapters: [ChapterModel],
    updatedAt: Date,
    moc: NSManagedObjectContext
  ) {
    guard let manga = mangaCrud.getManga(mangaId, moc: moc) else {
      print("MangaChapterDatasource Error -> Manga not found \(mangaId)")

      return
    }

    for chapter in chapters {
      if chapterCrud.createOrUpdateChapter(
        id: chapter.id,
        chapterNumber: chapter.number,
        title: chapter.title,
        numberOfPages: chapter.numberOfPages,
        publishAt: chapter.publishAt,
        manga: manga,
        moc: moc
      ) == nil {
        print("MangaChapterDatasource Error -> Failed to create entity")
      }
    }

    mangaCrud.updateLastUpdateAt(manga, date: updatedAt)
  }

}

extension MangaChapterDatasource {

  private func makeChapterFeedRequest(
    limit: Int,
    offset: Int
  ) async -> [ChapterModel] {
    let json: [String: Any] = await restRequester.makeGetRequest(
      url: "https://api.mangadex.org/manga/\(mangaId)/feed",
      parameters: [
        "translatedLanguage[]": "en",
        "limit": limit,
        "offset": offset
      ]
    )

    guard let dataJson = json["data"] as? [[String: Any]] else {
      print("MangaChapterDatasource -> Error creating response json")

      return []
    }

    return chapterParser.parseChapterData(mangaId: mangaId, data: dataJson)
  }

}
