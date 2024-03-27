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

  enum PageArray {
    case chapter
    case next
    case previous
  }

  @Published var pages: [ChapterPage]
  @Published var pageId: String?
  @Published var readingDirection: ReadingDirection
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

  var chapterPages: [PageModel]
  private var previousPages: [PageModel]
  private var nextPages: [PageModel]
  private var startTransitionPage: TransitionPageModel
  private var endTransitionPage: TransitionPageModel

  private var datasource: PagesDatasource
  private var transitionDatasource: PagesDatasource?

  private var nextChapter: ChapterModel?
  private var previousChapter: ChapterModel?

  private let source: Source
  private let mangaId: String
  private var chapter: ChapterModel
  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let httpClient: HttpClient
  private let viewMoc: NSManagedObjectContext

  private var observers = Set<AnyCancellable>()
  private var transitionObservers = Set<AnyCancellable>()

  // TODO: Search for chapter in the database instead of keeping in memory
  init(
    source: Source,
    mangaId: String,
    chapter: ChapterModel,
    readingDirection: ReadingDirection,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    httpClient: HttpClient,
    viewMoc: NSManagedObjectContext
  ) {
    self.source = source
    self.mangaId = mangaId
    self.chapter = chapter
    self.readingDirection = readingDirection
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.httpClient = httpClient
    self.viewMoc = viewMoc

    datasource = PagesDatasource(
      chapter: chapter,
      delegate: source.pagesDelegateType.init(
        httpClient: httpClient
      )
    )

    pages = []
    pageId = nil
    isLoading = false
    error = nil

    chapterPages = []
    previousPages = []
    nextPages = []

    startTransitionPage = .noPreviousChapter(currentChapter: chapter.id)
    endTransitionPage = .noNextChapter(currentChapter: chapter.id)

    setupObservers()
    updateNextChapter()
    updatePreviousChapter()
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

        self.chapterPages = $0
        self.previousPages = []
        self.nextPages = []
        self.startTransitionPage = makeStartTransitionPage()
        self.endTransitionPage = makeEndTransitionPage()
        
        self.updatePages()

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

        self.updateOrAppend(.chapter, with: $0)
        self.updatePages()
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

  private func updateNextChapter() {
    let chapter = viewMoc.performAndWait {
      try? chapterCrud.findNextChapter(
        self.chapter.id,
        mangaId: self.mangaId,
        moc: self.viewMoc
      )
    }

    guard let chapter else {
      nextChapter = nil

      return
    }

    nextChapter = .from(chapter)
  }

  private func updatePreviousChapter() {
    let chapter = viewMoc.performAndWait {
      try? chapterCrud.findPreviousChapter(
        self.chapter.id,
        mangaId: self.mangaId,
        moc: self.viewMoc
      )
    }

    guard let chapter else {
      previousChapter = nil

      return
    }

    previousChapter = .from(chapter)
  }

  private func updateOrAppend(
    _ pageArray: PageArray,
    with pages: [PageModel]
  ) {
    for page in pages {
      updateOrAppend(pageArray, with: page)
    }
  }

  private func updateOrAppend(
    _ pageArray: PageArray,
    with page: PageModel
  ) {
    switch pageArray {
    case .chapter:
      if let i = chapterPages.firstIndex(where: { $0.id == page.id }) {
        chapterPages[i] = page
      } else {
        chapterPages.append(page)
      }

    case .next:
      if let i = nextPages.firstIndex(where: { $0.id == page.id }) {
        nextPages[i] = page
      } else {
        nextPages.append(page)
      }

    case .previous:
      if let i = previousPages.firstIndex(where: { $0.id == page.id }) {
        previousPages[i] = page
      } else {
        previousPages.append(page)
      }
    }
  }

  private func makeStartTransitionPage() -> TransitionPageModel {
    if let previousChapter {
      return .transitionToPrevious(from: chapter.description, to: previousChapter.description)
    }

    return .noPreviousChapter(currentChapter: chapter.description)
  }

  private func makeEndTransitionPage() -> TransitionPageModel {
    if let nextChapter {
      return .transitionToNext(from: chapter.description, to: nextChapter.description)
    }

    return .noNextChapter(currentChapter: chapter.description)
  }

  private func updatePages() {
    let chapterPages = chapterPages.map { ChapterPage.page($0) }
    let previousPages = previousPages.map { ChapterPage.page($0) }
    let nextPages = nextPages.map { ChapterPage.page($0) }
    let startPage = ChapterPage.transition(self.startTransitionPage)
    let endPage = ChapterPage.transition(self.endTransitionPage)

    pages = previousPages + [startPage] + chapterPages + [endPage] + nextPages
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

  // TODO: Keep transition state to better know when to call moveTo... methods
  func onPageTask(_ pageId: String) async {
    if pageId == endTransitionPage.id {
      onTransitionPageToNext()
    } else if pageId == startTransitionPage.id {
      onTransitionPageToPrevious()
    } else if pageId == nextPages.first?.id {
      onMoveToNext()
    } else if pageId == previousPages.last?.id {
      onMoveToPrevious()
    } else {
      await datasource.loadPagesIfNeeded(pageId)
    }
  }

  func reloadPages(startingAt page: PageModel) async {
    guard let i = pages.firstIndex(where: { $0.id == page.id }) else { return }

    let j = min(i + 10, pages.count)
    let pages = chapterPages[i..<j].compactMap {
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
      transitionDatasource == nil,
      let nextChapter
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
        self?.updateOrAppend(.next, with: $0)
        self?.updatePages()
      }
      .store(in: &transitionObservers)

    Task(priority: .medium) {
      await transitionDatasource.prepareDatasource()
      await transitionDatasource.loadStart()
    }
  }

  private func onTransitionPageToPrevious() {
    guard
      transitionDatasource == nil,
      let previousChapter
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
        self?.updateOrAppend(.previous, with: $0)
        self?.updatePages()
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

    guard 
      let transitionDatasource,
      let nextChapter
    else {
      return
    }

    print("ChapterReaderViewModel -> Moved to the next chapter")

    self.transitionDatasource = nil
    self.datasource = transitionDatasource


    let current = chapter

    self.chapter = nextChapter
    self.previousChapter = current

    updateNextChapter()
    setupObservers()
  }

  private func onMoveToPrevious() {
    transitionObservers.forEach { $0.cancel() }
    transitionObservers.removeAll()

    guard 
      let transitionDatasource,
      let previousChapter
    else {
      return
    }

    print("ChapterReaderViewModel -> Moved to the previous chapter")

    self.transitionDatasource = nil
    self.datasource = transitionDatasource
    
    let current = chapter

    self.chapter = previousChapter
    self.nextChapter = current

    updatePreviousChapter()
    setupObservers()
  }

}

// MARK: Useful helpers
extension ChapterReaderViewModel {

  var selectedPageNumber: Int {
    guard let pageId else { return 0 }

    if pageId == startTransitionPage.id {
      return 1
    }

    if pageId == endTransitionPage.id {
      return chapterPages.count
    }

    let index = chapterPages.map { $0.id }.firstIndex(of: pageId) ?? 0

    return max(1, min(index + 1, chapterPages.count))
  }

}
