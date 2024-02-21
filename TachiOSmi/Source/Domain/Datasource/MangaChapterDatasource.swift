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

  private let chapterParser: ChapterParser
  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let systemDateTime: SystemDateTimeType
  private let moc: NSManagedObjectContext

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

  init(
    mangaId: String,
    chapterParser: ChapterParser,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    systemDateTime: SystemDateTimeType,
    moc: NSManagedObjectContext
  ) {
    self.mangaId        = mangaId
    self.chapterParser  = chapterParser
    self.mangaCrud      = mangaCrud
    self.chapterCrud    = chapterCrud
    self.systemDateTime = systemDateTime
    self.moc            = moc

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

      self.chapters.value = self.fetchLocalChapters()

      do {
        try Task.checkCancellation()

        if isForceRefresh {
          try await self.chapterRefresh()
        } else {
          try await self.chapterRefreshIfNeeded()
        }

        self.state.value = .normal

        print("MangaChapterDatasource -> Fetch task ended")
      } catch {
        self.state.value = .cancelled

        print("MangaChapterDatasource -> Fetch task cancelled")
      }

      self.fetchTask = nil
    }
  }

  private func fetchLocalChapters() -> [ChapterModel] {
    let chapters = chapterCrud
      .getAllChapters(mangaId: mangaId, moc: moc)
      .map { ChapterModel.from($0) }
      .sorted {
        guard
          let lhs = $0.number,
          let rhs = $1.number
        else {
          return $0.publishAt < $1.publishAt
        }

        return lhs < rhs
      }

    return chapters
  }

  private func chapterRefresh() async throws {
    let results = try await fetchChapters()

    chapters.value = results.sorted {
      guard
        let lhs = $0.number,
        let rhs = $1.number
      else {
        return $0.publishAt < $1.publishAt
      }

      return lhs < rhs
    }
  }

  private func chapterRefreshIfNeeded() async throws {
    guard let manga = mangaCrud.getManga(mangaId, moc: moc) else {
      print("MangaChapterDatasource -> Manga not found \(mangaId)")

      return
    }

    if let lastUpdateAt = manga.lastUpdateAt {
      if systemDateTime.comparator.isDate(
        lastUpdateAt,
        lessThanOrEqual: systemDateTime.calculator.removeDays(5, to: systemDateTime.now)
      ) {
        try await chapterRefresh()
      }
    } else {
      try await chapterRefresh()
    }
  }

  private func fetchChapters() async throws -> [ChapterModel] {
    print("MangaChapterDatasource -> Fetch task intiated")

    var results = [ChapterModel]()
    let limit   = 25
    var offset  = 0

    while true {
      try Task.checkCancellation()

      let result = try await updateChapters(limit: limit, offset: offset)

      if result.isEmpty { break }

      offset += limit

      results.append(contentsOf: result)
    }

    mangaCrud.updateLastUpdateAt(mangaId, date: Date(), moc: moc)

    return results
  }

  private func updateChapters(
    limit: Int,
    offset: Int
  ) async throws -> [ChapterModel] {
    let urlString = "https://api.mangadex.org/manga/\(mangaId)/feed"

    let parameters: [String: Any] = [
      "translatedLanguage[]": "en",
      "limit": limit,
      "offset": offset
    ]

    var urlParameters = URLComponents(string: urlString)
    urlParameters?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

    guard let url = urlParameters?.url else {
      print ("MangaChapterDatasource -> Error creating url")

      return []
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let response = response as? HTTPURLResponse else {
        print("MangaChapterDatasource -> Response parse error")

        return []
      }

      guard response.statusCode == 200 else {
        print("MangaChapterDatasource -> Received response with code \(response.statusCode)")

        return []
      }

      guard 
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let dataJson = json["data"] as? [[String: Any]]
      else {
        print("MangaChapterDatasource -> Error creating response json")

        return []
      }

      return chapterParser.parseChapterData(mangaId: mangaId, data: dataJson)
    }  catch {
      if let cancellationError = error as? CancellationError {
        throw cancellationError
      } else {
        print("MangaChapterDatasource -> Error during request \(error)")
      }
    }

    return []
  }

}
