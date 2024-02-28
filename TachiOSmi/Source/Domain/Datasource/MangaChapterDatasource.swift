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

  @MainActor var hasMorePages = true
  @MainActor private var currentPage = 0
  @MainActor private var results = [ChapterModel]() {
    didSet { count.valueOnMain = results.count }
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
    count    = CurrentValueSubject(0)
    state    = CurrentValueSubject(.starting)
    error    = CurrentValueSubject(nil)
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
          results = try await self.fetchChapters()
        }

        await MainActor.run { [results] in
          self.results = results
          self.sendNextChapters()
        }

        let newResults = try await fetchRemoteChaptersIfNeeded()

        if !newResults.isEmpty {
          await MainActor.run { [newResults] in
            self.results = newResults
            self.sendAllLoadedChapters()
          }

          try await updateDatabase(
            chapters: newResults,
            updatedAt: self.systemDateTime.now
          )
        }
      } catch { erro = catchError(error) }

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
        try await Task.sleep(nanoseconds: 5_000_000_000)

        results = try await self.fetchChapters()

        await MainActor.run { [results] in
          self.results = results
          self.sendAllLoadedChapters()      
        }

        try await updateDatabase(
          chapters: results,
          updatedAt: self.systemDateTime.now
        )
      } catch { erro = catchError(error) }

      await MainActor.run { [erro] in
        self.state.valueOnMain = .normal
        self.error.valueOnMain = erro
        self.fetchTask = nil
      }
    }
  }

  func loadNextPage() async {
    await MainActor.run {
      sendNextChapters()
    }
  }

  private func fetchLocalChapters() async throws -> [ChapterModel] {
    return try chapterCrud
      .getAllChapters(mangaId: mangaId, moc: viewMoc)
      .map { ChapterModel.from($0) }
      .sorted(by: MangaChapterDatasource.sortByNumber)
  }

  private func fetchRemoteChaptersIfNeeded() async throws -> [ChapterModel] {
    guard let manga = try mangaCrud.getManga(mangaId, moc: viewMoc) else {
      throw CrudError.mangaNotFound(id: mangaId)
    }

    guard let lastUpdateAt = manga.lastUpdateAt else {
      return try await fetchChapters()
    }

    if systemDateTime.comparator.isDate(
      lastUpdateAt,
      lessThanOrEqual: systemDateTime.calculator.removeDays(5, to: systemDateTime.now)
    ) {
      return try await fetchChapters()
    }

    return []
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
extension MangaChapterDatasource {

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

// MARK: Error
extension MangaChapterDatasource {

  private func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      print("MangaChapterDatasource -> Task cancelled")

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as CrudError:
      return .databaseError(error.localizedDescription)

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
  }

}

// MARK: Network
extension MangaChapterDatasource {

  private func fetchChapters() async throws -> [ChapterModel] {
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

    return chapterParser
      .parseChapterData(mangaId: mangaId, data: dataJson)
      .filter { $0.numberOfPages > 0 }
  }

}
