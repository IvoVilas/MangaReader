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

  var title: String
  var cover: Data?
  var description: String?
  var isSaved: Bool
  var status: MangaStatus
  var authors: [AuthorModel]
  var tags: [TagModel]
  var chapters: [ChapterModel]
  var chapterCount: Int
  var isLoading: Bool
  var isImageLoading: Bool
  var error: DatasourceError?
  var info: String?

  private var readingDirection: ReadingDirection

  private let mangaId: String
  private let source: Source
  private let chaptersDatasource: ChaptersDatasource
  private let detailsDatasource: DetailsDatasource
  private let mangaCrud: MangaCrud
  private let viewMoc: NSManagedObjectContext

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
    self.mangaId = manga.id
    self.source = source
    self.mangaCrud = mangaCrud
    self.viewMoc = viewMoc

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

    title = manga.title
    cover = manga.cover
    isSaved = manga.isSaved
    status = .unknown
    authors = []
    tags = []
    chapters = []
    chapterCount = 0
    isLoading = false
    isImageLoading = false
    readingDirection = .leftToRight

    detailsDatasource.detailsPublisher
      .map { $0.title }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.title = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.description }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.description = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.isSaved }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.isSaved = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.status }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.status = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.authors }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.authors = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.tags }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.tags = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .compactMap { $0.cover }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.cover = $0 }
      .store(in: &observers)

    detailsDatasource.detailsPublisher
      .map { $0.readingDirection }
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.readingDirection = $0 }
      .store(in: &observers)

    chaptersDatasource.chaptersPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.chapters = $0 }
      .store(in: &observers)

    chaptersDatasource.countPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.chapterCount = $0 }
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
      .sink { [weak self] in self?.readingDirection = $0 }
      .store(in: &observers)

    changedChapter
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] chapter in
        guard let self else { return }

        if let index = self.chapters.firstIndex(where: { $0.id == chapter.id }) {
          self.chapters[index] = chapter
        }
      }
      .store(in: &observers)
  }

  private func saveManga(isSaved: Bool) async throws {
    try await viewMoc.perform {
      guard let manga = try self.mangaCrud.getManga(self.mangaId, moc: self.viewMoc) else {
        throw CrudError.mangaNotFound(id: self.mangaId)
      }

      self.mangaCrud.updateIsSaved(manga, isSaved: isSaved)

      if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
    }
  }

}

extension MangaDetailsViewModel {

  func saveManga(_ save: Bool) async {
    await MainActor.run { isSaved = save }

    do {
      try await self.saveManga(isSaved: save)
    } catch {
      await MainActor.run {
        self.isSaved = !save
        self.error = DatasourceError.catchError(error)
      }
    }

    await MainActor.run { info = save ? "Manga added to library" : "Manga removed from library" }
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

  func loadNextChapters(_ id: String) async {
    if id == chapters.last?.id {
      await chaptersDatasource.loadNextPage()
    }
  }

  func buildReaderViewModel(
    _ chapter: ChapterModel
  ) -> ChapterReaderViewModel {
    return ChapterReaderViewModel(
      source: source,
      mangaId: mangaId,
      mangaTitle: title,
      chapter: chapter,
      readingDirection: readingDirection,
      mangaCrud: AppEnv.env.mangaCrud,
      chapterCrud: AppEnv.env.chapterCrud,
      httpClient: AppEnv.env.httpClient,
      changedChapter: changedChapter,
      changedReadingDirection: changedReadingDirection,
      viewMoc: viewMoc
    )
  }

}
