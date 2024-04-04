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

@Observable
final class MangaDetailsViewModel {

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

  var manga: MangaModel
  var chapters: [ChapterCell]
  var chaptersCount: Int
  var missingChaptersCount: Int
  var isLoading: Bool
  var isImageLoading: Bool
  var error: DatasourceError?
  var info: String?

  private let source: Source
  private let chaptersDatasource: ChaptersDatasource
  private let detailsDatasource: DetailsDatasource
  private let mangaCrud: MangaCrud
  private let viewMoc: NSManagedObjectContext

  private let sortChaptersUseCase: SortChaptersUseCase
  private let missingChaptersUseCase: MissingChaptersUseCase

  private let changedChapter: PassthroughSubject<ChapterModel, Never>
  private let changedReadingDirection: PassthroughSubject<ReadingDirection, Never>
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
    viewMoc: NSManagedObjectContext
  ) {
    self.source = source
    self.mangaCrud = mangaCrud
    self.viewMoc = viewMoc

    sortChaptersUseCase = SortChaptersUseCase()
    missingChaptersUseCase = MissingChaptersUseCase()

    changedChapter = PassthroughSubject()
    changedReadingDirection = PassthroughSubject()

    chaptersDatasource = ChaptersDatasource(
      mangaId: manga.id,
      delegate: source.chaptersDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      systemDateTime: systemDateTime,
      viewMoc: viewMoc
    )
    detailsDatasource = DetailsDatasource(
      manga: manga,
      delegate: source.detailsDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      coverCrud: coverCrud,
      authorCrud: authorCrud, 
      tagCrud: tagCrud,
      viewMoc: viewMoc
    )

    self.manga = MangaModel(
      id: manga.id,
      title: manga.title,
      description: nil,
      isSaved: manga.isSaved,
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

    detailsDatasource.detailsPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.manga = $0 }
      .store(in: &observers)

    chaptersDatasource.chaptersPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.setChapters($0) }
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

    changedReadingDirection
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        guard let self else { return }

        let manga = self.manga

        self.manga = MangaModel(
          id: manga.id,
          title: manga.title,
          description: manga.description,
          isSaved: manga.isSaved,
          status: manga.status,
          readingDirection: $0,
          cover: manga.cover,
          tags: manga.tags,
          authors: manga.authors
        )
      }
      .store(in: &observers)

    changedChapter
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.changeChapter($0) }
      .store(in: &observers)
  }

  private func saveManga(isSaved: Bool) async throws {
    try await viewMoc.perform {
      guard let manga = try self.mangaCrud.getManga(self.manga.id, moc: self.viewMoc) else {
        throw CrudError.mangaNotFound(id: self.manga.id)
      }

      self.mangaCrud.updateIsSaved(manga, isSaved: isSaved)

      if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
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

  private func changeChapter(_ changed: ChapterModel) {
    let index = self.chapters.firstIndex{
      switch $0 {
      case .chapter(let chapter):
        return chapter.id == changed.id

      case .missing:
        return false
      }
    }

    if let index {
      self.chapters[index] = .chapter(changed)
    }
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
    if chapters.isEmpty {
      await detailsDatasource.setupData()
      await chaptersDatasource.setupData()
    }
  }

  func forceRefresh() async {
    await detailsDatasource.refresh()
    await chaptersDatasource.refresh()
  }

  func buildReaderViewModel(
    _ chapter: ChapterModel
  ) -> ChapterReaderViewModel {
    return ChapterReaderViewModel(
      source: source,
      mangaId: manga.id,
      mangaTitle: manga.title,
      chapter: chapter,
      readingDirection: manga.readingDirection,
      mangaCrud: AppEnv.env.mangaCrud,
      chapterCrud: AppEnv.env.chapterCrud,
      httpClient: AppEnv.env.httpClient,
      changedChapter: changedChapter,
      changedReadingDirection: changedReadingDirection,
      viewMoc: viewMoc
    )
  }

}

// MARK: Helpers
extension MangaDetailsViewModel {

  func addMissingChapters(
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
          if chapter.number == m.number - 1 {
            return true
          }
        }

        return false
      }

      if let index {
        mappedChapters.insert(.missing(m), at: index)
      }
    }

    return mappedChapters
  }

}
