//
//  MangaDetailsViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class MangaDetailsViewModel: ObservableObject {

  @Published var manga: MangaModel
  @Published var chapters: [ChapterCell]
  @Published var chaptersCount: Int
  @Published var missingChaptersCount: Int
  @Published var isLoading: Bool
  @Published var isImageLoading: Bool
  @Published var error: DatasourceError?
  @Published var info: String?

  private let chaptersProvider: MangaChaptersProvider
  private let chaptersDatasource: ChaptersDatasource

  private let detailsProvider: MangaDetailsProvider
  private let detailsDatasource: DetailsDatasource

  private let source: Source
  private let mangaCrud: MangaCrud
  private let viewMoc: NSManagedObjectContext
  private let moc: NSManagedObjectContext

  private let sortChaptersUseCase: SortChaptersUseCase
  private let missingChaptersUseCase: MissingChaptersUseCase

  private var observers = Set<AnyCancellable>()

  init(
    source: Source,
    manga: MangaSearchResult,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    coverCrud: CoverCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    httpClient: HttpClient,
    systemDateTime: SystemDateTimeType,
    appOptionsStore: AppOptionsStore,
    container: NSPersistentContainer
  ) {
    self.source = source
    self.mangaCrud = mangaCrud
    self.viewMoc = container.viewContext
    self.moc = container.newBackgroundContext()

    sortChaptersUseCase = SortChaptersUseCase()
    missingChaptersUseCase = MissingChaptersUseCase()

    chaptersProvider = MangaChaptersProvider(
      mangaId: manga.id,
      viewMoc: viewMoc
    )
    chaptersDatasource = ChaptersDatasource(
      mangaId: manga.id,
      delegate: source.chaptersDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      systemDateTime: systemDateTime,
      moc: moc
    )

    detailsProvider = MangaDetailsProvider(
      mangaId: manga.id,
      coverCrud: coverCrud,
      viewMoc: viewMoc
    )
    detailsDatasource = DetailsDatasource(
      source: source, 
      mangaId: manga.id,
      delegate: source.detailsDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      coverCrud: coverCrud,
      authorCrud: authorCrud, 
      tagCrud: tagCrud,
      appOptionsStore: appOptionsStore,
      moc: moc
    )

    self.manga = MangaModel(
      id: manga.id,
      title: manga.title,
      description: nil,
      isSaved: false,
      source: source,
      status: .unknown,
      readingDirection: .leftToRight,
      cover: manga.cover,
      tags: [],
      authors: []
    )

    chapters = []
    isLoading = false
    isImageLoading = false
    chaptersCount = 0
    missingChaptersCount = 0

    detailsProvider.$details
      .removeDuplicates()
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.manga = $0
      }
      .store(in: &observers)

    chaptersProvider.$chapters
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.setChapters($0)
      }
      .store(in: &observers)

    Publishers.CombineLatest(
      detailsDatasource.statePublisher,
      chaptersDatasource.statePublisher
    )
    .map { $0.0.isLoading || $0.1.isLoading }
    .removeDuplicates()
    .receive(on: DispatchQueue.main)
    .sink { [weak self] in self?.isLoading = $0 }
    .store(in: &observers)

    Publishers.CombineLatest(
      detailsDatasource.errorPublisher,
      chaptersDatasource.errorPublisher
    )
    .receive(on: DispatchQueue.main)
    .map {
      if let error = $0 { return error }
      if let error = $1 { return error }

      return nil
    }
    .sink { [weak self] in self?.error = $0 }
    .store(in: &observers)
  }

  private func saveManga(isSaved: Bool) async throws {
    try await viewMoc.perform {
      guard let manga = try self.mangaCrud.getManga(self.manga.id, moc: self.viewMoc) else {
        throw CrudError.mangaNotFound(id: self.manga.id)
      }

      self.mangaCrud.updateIsSaved(manga, isSaved: isSaved)

      _ = try self.viewMoc.saveIfNeeded()
    }
  }

  // TODO: Maybe remove from main thread
  private func setChapters(_ chapters: [ChapterModel]) {
    let sortedChapters = sortChaptersUseCase.sortByNumber(chapters)
    let missing = missingChaptersUseCase.calculateMissingChapters(sortedChapters)

    self.chapters = addMissingChapters(missing, to: sortedChapters)
    self.chaptersCount = chapters.count
    self.missingChaptersCount = missing.reduce(into: 0) { $0 += $1.count }
  }

}

extension MangaDetailsViewModel {

  func saveManga(_ save: Bool) async {
    await MainActor.run {
      let manga = self.manga

      self.manga = MangaModel(
        id: manga.id,
        title: manga.title,
        description: manga.description,
        isSaved: save,
        source: manga.source,
        status: manga.status,
        readingDirection: manga.readingDirection,
        cover: manga.cover,
        tags: manga.tags,
        authors: manga.authors
      )
    }

    do {
      try await self.saveManga(isSaved: save)

      await MainActor.run {
        info = save ? "Manga added to library" : "Manga removed from library"
      }
    } catch {
      await MainActor.run {
        self.error = DatasourceError.catchError(error)
      }
    }
  }

  func setupData() async {
    await detailsDatasource.refresh()
    await chaptersDatasource.refresh()
  }

  func forceRefresh() async {
    await detailsDatasource.refresh(force: true)
    await chaptersDatasource.refresh(force: true)
  }

}

// MARK: Helpers
extension MangaDetailsViewModel {

  private func addMissingChapters(
    _ missing: [MissingChaptersModel],
    to chapters: [ChapterModel]
  ) -> [ChapterCell] {
    var mappedChapters = chapters.map { ChapterCell.chapter($0) }

    guard !missing.isEmpty else {
      return mappedChapters
    }

    for m in missing {
      let index = mappedChapters.firstIndex {
        switch $0 {
        case .missing:
          return false

        case .chapter(let chapter):
          return chapter.number == m.number - 1
        }
      }

      if let index {
        mappedChapters.insert(.missing(m), at: index)
      }
    }

    return mappedChapters
  }

}

extension MangaDetailsViewModel {

  enum ChapterCell: Identifiable {
    case chapter(ChapterModel)
    case missing(MissingChaptersModel)

    var id: String {
      switch self {
      case .chapter(let chapter):
        return chapter.id

      case .missing(let missing):
        return missing.id
      }
    }

    var number: Double? {
      switch self {
      case .chapter(let chapter):
        return chapter.number

      case .missing(let missing):
        return Double(missing.number)
      }
    }
  }

}

extension MangaDetailsViewModel {

  func getNavigator(_ chapter: ChapterModel) -> MangaReaderNavigator {
    return MangaReaderNavigator(
      source: source, 
      mangaId: manga.id,
      mangaTitle: manga.title,
      chapter: chapter,
      readingDirection: manga.readingDirection
    )
  }

}
