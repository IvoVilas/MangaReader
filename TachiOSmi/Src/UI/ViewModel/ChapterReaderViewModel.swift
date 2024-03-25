//
//  ChapterReaderViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class ChapterReaderViewModel: ObservableObject {

  @Published var pages: [PageModel]
  @Published var readingDirection: ReadingDirection
  @Published var pagesCount: Int
  @Published var pageId: String?
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

  private var datasource: PagesDatasource
  private var transitionDatasource: PagesDatasource?

  private let source: Source
  private let mangaId: String
  private var chapter: ChapterModel
  private let chapters: [ChapterModel]
  private let mangaCrud: MangaCrud
  private let httpClient: HttpClient
  private let viewMoc: NSManagedObjectContext

  private var observers = Set<AnyCancellable>()
  private var transitionObservers = Set<AnyCancellable>()

  // TODO: Search for chapter in the database instead of keeping in memory
  init(
    readingDirection: ReadingDirection,
    source: Source,
    mangaId: String,
    chapter: ChapterModel,
    chapters: [ChapterModel],
    mangaCrud: MangaCrud,
    httpClient: HttpClient,
    viewMoc: NSManagedObjectContext
  ) {
    self.source = source
    self.mangaId = mangaId
    self.chapter = chapter
    self.chapters = chapters
    self.mangaCrud = mangaCrud
    self.httpClient = httpClient
    self.viewMoc = viewMoc
    self.readingDirection = readingDirection

    datasource = PagesDatasource(
      chapter: chapter,
      delegate: source.pagesDelegateType.init(
        httpClient: httpClient
      )
    )

    pages = []
    pagesCount = 0
    pageId = nil
    isLoading = false
    error = nil

    setupObservers()
  }

  private func setupObservers() {
    observers.forEach { $0.cancel() }
    observers.removeAll()

    let publisher = datasource.pagesPublisher
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .filter { !$0.isEmpty }

    publisher
      .first()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        guard let self else { return }

        var pages = $0

        pages.append(.transition(chapterId))
        if let previousId = self.previousChapterId {
          pages.insert(.transition(previousId), at: 0)
        }

        self.pages = pages
        self.pagesCount = self.pagesBetweenTransitions().count

        if pageId == nil {
          pageId = $0.first?.id
        }
      }
      .store(in: &observers)

    publisher
      .dropFirst()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        guard let self else { return }

        self.updateOrAppend($0)
      }
      .store(in: &observers)

    datasource.statePublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.isLoading = $0.isLoading }
      .store(in: &observers)

    datasource.errorPublisher
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] in self?.error = $0 }
      .store(in: &observers)
  }

  private func updateOrAppend(
    _ pages: [PageModel]
  ) {
    for page in pages {
      updateOrAppend(page)
    }
  }

  private func updateOrAppend(
    _ page: PageModel
  ) {
    if let i = pages.firstIndex(where: { $0.id == page.id }) {
      pages[i] = page
    } else {
      pages.append(page)
    }
  }

  private func updateOrPrepend(
    _ pages: [PageModel]
  ) {
    for page in pages {
      updateOrPrepend(page)
    }
  }

  private func updateOrPrepend(
    _ page: PageModel
  ) {
    if let i = pages.firstIndex(where: { $0.id == page.id }) {
      pages[i] = page
    } else {
      var index = 0

      if 
        let previousChapterId,
        let pos = pages.transitionPageIndex(withId: previousChapterId)
      {
        index = pos
      }

      pages.insert(page, at: index)
    }
  }

  private func updateReadingDirection(to direction: ReadingDirection) async throws {
    try await viewMoc.perform {
      guard let manga = try self.mangaCrud.getManga(self.mangaId, moc: self.viewMoc) else {
        throw CrudError.mangaNotFound(id: self.mangaId)
      }

      self.mangaCrud.updateReadingDirection(manga, direction: direction)

      if !self.viewMoc.saveIfNeeded(rollbackOnError: true).isSuccess {
        throw CrudError.saveError
      }
    }
  }

}

// MARK: Actions
extension ChapterReaderViewModel {

  func changeReadingDirection(to direction: ReadingDirection) async {
    await MainActor.run { readingDirection = direction }

    do {
      try await self.updateReadingDirection(to: direction)
    } catch {
      return
    }
  }

  func fetchPages() async {
    await datasource.prepareDatasource()
    await datasource.loadStart()
  }

  func onPageTask(_ pageId: String) async {
    if pageId == pages.transitionPage(withId: chapterId)?.id {
      onTransitionPageToNext()
    } else if let previousChapterId, pageId == pages.transitionPage(withId: previousChapterId)?.id {
      onTransitionPageToPrevious()
    } else if pageId == pages.pageAfterTransition(withId: chapterId)?.id {
      onMoveToNext()
    } else if let previousChapterId, pageId == pages.pageBeforeTransition(withId: previousChapterId)?.id {
      onMoveToPrevious()
    } else {
      await datasource.loadPagesIfNeeded(pageId)
    }
  }

  func reloadPages(startingAt page: PageModel) async {
    guard let i = pages.firstIndex(where: { $0.id == page.id }) else { return }

    let j = min(i + 10, pages.count)
    let pages = pages[i..<j].compactMap {
      switch $0 {
      case .notFound(let url, let pos):
        return (url, pos)

      default: 
        return nil
      }
    }

    await datasource.reloadPages(pages)
  }

}

// MARK: OnPage Actions
extension ChapterReaderViewModel {

  private func onTransitionPageToNext() {
    guard
      let i = chapters.firstIndex(of: chapter),
      let nextChapter = chapters.safeGet(i - 1)
    else {
      return
    }

    print("ChapterReaderViewModel -> Entered transition page to next chapter")
    let transitionDatasource = PagesDatasource(
      chapter: nextChapter,
      delegate: source.pagesDelegateType.init(
        httpClient: httpClient
      )
    )

    self.transitionDatasource = transitionDatasource

    transitionDatasource.pagesPublisher
      .debounce(for: 0.3, scheduler: DispatchQueue.main)
      .sink { [weak self] in
        self?.updateOrAppend($0)
      }
      .store(in: &transitionObservers)

    Task(priority: .medium) {
      await transitionDatasource.prepareDatasource()
      await transitionDatasource.loadStart()
    }
  }

  private func onTransitionPageToPrevious() {
    guard
      let i = chapters.firstIndex(of: chapter),
      let previousChapter = chapters.safeGet(i + 1)
    else {
      return
    }

    print("ChapterReaderViewModel -> Entered transition page to previous chapter")
    let transitionDatasource = PagesDatasource(
      chapter: previousChapter,
      delegate: source.pagesDelegateType.init(
        httpClient: httpClient
      )
    )

    self.transitionDatasource = transitionDatasource

    transitionDatasource.pagesPublisher
      .debounce(for: 0.3, scheduler: DispatchQueue.main)
      .sink { [weak self] in
        self?.updateOrPrepend($0)
      }
      .store(in: &transitionObservers)

    Task(priority: .medium) {
      await transitionDatasource.prepareDatasource()
      await transitionDatasource.loadEnd()
    }
  }

  private func onMoveToNext() {
    transitionObservers.forEach { $0.cancel() }
    transitionObservers.removeAll()

    guard let transitionDatasource else {
      return
    }

    print("ChapterReaderViewModel -> Moved to the next chapter")

    if let i = pages.transitionPageIndex(withId: chapterId) {
      DispatchQueue.main.sync {
        pages.removeSubrange(0..<i)
      }
    }

    self.transitionDatasource = nil
    self.datasource = transitionDatasource
    self.chapter = transitionDatasource.chapter

    setupObservers()
  }

  private func onMoveToPrevious() {
    transitionObservers.forEach { $0.cancel() }
    transitionObservers.removeAll()

    guard let transitionDatasource else {
      return
    }

    print("ChapterReaderViewModel -> Moved to the previous chapter")

    if let i = pages.transitionPageIndex(withId: transitionDatasource.chapter.id) {
      DispatchQueue.main.sync {
        pages.removeSubrange(i + 1..<pages.count)
      }
    }

    self.transitionDatasource = nil
    self.datasource = transitionDatasource
    self.chapter = transitionDatasource.chapter

    setupObservers()
  }

}

// MARK: Useful helpers
extension ChapterReaderViewModel {

  private var chapterId: String { chapter.id }

  private var previousChapterId: String? {
    guard
      let i = chapters.firstIndex(of: chapter),
      let previousChapter = chapters.safeGet(i + 1)
    else {
      return nil
    }

    return previousChapter.id
  }

  var selectedPageNumber: Int {
    guard let pageId else { return 0 }

    let index = pages.map { $0.id }.firstIndex(of: pageId) ?? 0

    guard 
      let previousChapterId,
      pages.transitionPageIndex(withId: previousChapterId) != nil
    else {
      return index + 1
    }

    return index
  }

  func pagesBetweenTransitions() -> [PageModel] {
    let i: Int
    let j: Int

    if let previousChapterId {
      if let t = pages.transitionPageIndex(withId: previousChapterId) {
        i = t + 1
      } else {
        i = 0
      }
    } else {
      i = 0
    }

    j = pages.transitionPageIndex(withId: chapterId) ?? pages.count

    guard i <= j else { return pages }

    return Array(pages[i..<j])
  }

}

// MARK: Get transition pages
extension Array<PageModel> {

  func transitionPageIndex(withId pageId: String) -> Int? {
    return self.firstIndex {
      switch $0 {
      case .transition(let id):
        return pageId == id

      default:
        return false
      }
    }
  }

  func transitionPage(withId pageId: String) -> PageModel? {
    if let i = transitionPageIndex(withId: pageId) {
      return safeGet(i)
    }

    return nil
  }

  func pageAfterTransition(withId pageId: String) -> PageModel? {
    if let i = transitionPageIndex(withId: pageId) {
      return safeGet(i + 1)
    }

    return nil
  }

  func pageBeforeTransition(withId pageId: String) -> PageModel? {
    if let i = transitionPageIndex(withId: pageId) {
      return safeGet(i - 1)
    }

    return nil
  }

}
