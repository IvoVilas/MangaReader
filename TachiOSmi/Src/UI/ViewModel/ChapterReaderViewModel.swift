//
//  ChapterReaderViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 02/04/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

// TODO: Maybe start to load new datasource on transition page to smother experience
final class ChapterReaderViewModel: ObservableObject {

  @Published var pages: [ChapterPage]
  @Published var pageId: String?
  @Published var readingDirection: ReadingDirection
  @Published var chapter: ChapterModel
  @Published var missingNextChapters: Int
  @Published var missingPreviousChapters: Int
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

  private var isEmpty: Bool

  private var datasource: PagesDatasource
  private let delegate: PagesDelegateType

  private var nextChapter: ChapterModel?
  private var previousChapter: ChapterModel?

  let mangaTitle: String
  private let mangaId: String
  private let source: Source
  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let httpClient: HttpClientType
  private let appOptionsStore: AppOptionsStore
  private let viewMoc: NSManagedObjectContext
  private let moc: NSManagedObjectContext

  let closeReaderEvent = PassthroughSubject<Void, Never>()
  private let receivedPagesEvent = CurrentValueSubject<Bool, Never>(false)
  private var observers = Set<AnyCancellable>()

  init(
    source: Source,
    mangaId: String,
    mangaTitle: String,
    chapter: ChapterModel,
    readingDirection: ReadingDirection,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    httpClient: HttpClientType,
    appOptionsStore: AppOptionsStore,
    container: NSPersistentContainer
  ) {
    self.source = source
    self.mangaId = mangaId
    self.mangaTitle = mangaTitle
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.httpClient = httpClient
    self.appOptionsStore = appOptionsStore
    self.viewMoc = container.viewContext
    self.moc = container.newBackgroundContext()

    delegate = source.pagesDelegateType.init(httpClient: httpClient)
    datasource = PagesDatasource(
      mangaId: mangaId,
      chapter: chapter,
      delegate: delegate,
      appOptionsStore: appOptionsStore
    )

    self.pages = []
    self.pageId = nil
    self.chapter = chapter
    self.readingDirection = readingDirection
    self.missingNextChapters = 0
    self.missingPreviousChapters = 0
    self.isLoading = true
    self.error = nil
    self.isEmpty = true

    resetViewModel()
  }

  private func resetViewModel(
    prepareDatasource: Bool = false
  ) {
    receivedPagesEvent.value = false
    pageId = nil

    setupObservers()

    // TODO: Some of these tasks can be parallel
    Task {
      await fetchAdjacentChapters()

      if prepareDatasource {
        await datasource.prepareDatasource()
      }
    }
  }

  private func setupObservers() {
    observers.forEach { $0.cancel() }
    observers.removeAll()

    let publisher = datasource.pagesPublisher
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .filter { !$0.isEmpty }

    publisher
      .dropFirst()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.updateOrAppend($0) }
      .store(in: &observers)

    publisher
      .first()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] pages in
        guard let self else { return }

        self.setPages(pages)

        self.receivedPagesEvent.value = true

        var pageId: String?
        let firstId = pages.first?.id

        if self.chapter.isRead {
          pageId = firstId
        } else {
          pageId = pages.safeGet(self.chapter.lastPageRead)?.id ?? firstId
        }

        if self.pageId == nil {
          self.pageId = pageId
        }
      }
      .store(in: &observers)

    Publishers.CombineLatest(
      datasource.statePublisher,
      receivedPagesEvent
    )
    .map { $0.0.isLoading || !$0.1 }
    .removeDuplicates()
    .receive(on: DispatchQueue.main)
    .sink { [weak self] in self?.isLoading = $0 }
    .store(in: &observers)

    datasource.errorPublisher
      .receive(on: DispatchQueue.main)
      .compactMap { $0 }
      .sink { [weak self] in self?.error = $0 }
      .store(in: &observers)
  }

  private func fetchAdjacentChapters() async {
    let context = viewMoc

    let (next, previous) = await context.perform {
      let next = try? self.chapterCrud.findNextChapter(
        self.chapter.id,
        mangaId: self.mangaId,
        moc: context
      )

      let previous = try? self.chapterCrud.findPreviousChapter(
        self.chapter.id,
        mangaId: self.mangaId,
        moc: context
      )

      let nextChapter: ChapterModel?
      let previousChapter: ChapterModel?

      if let next {
        nextChapter = .from(next)
      } else {
        nextChapter = nil
      }

      if let previous {
        previousChapter = .from(previous)
      } else {
        previousChapter = nil
      }

      return (nextChapter, previousChapter)
    }

    nextChapter = next
    previousChapter = previous

    missingNextChapters = calculateMissingChapters(
      from: chapter.number,
      to: next?.number
    )

    missingPreviousChapters = calculateMissingChapters(
      from: previous?.number,
      to: chapter.number
    )

    DispatchQueue.main.async {
      self.updateTransitionPages(
        previous: self.makeEndTransitionPage(),
        next: self.makeStartTransitionPage()
      )
    }
  }

  private func updateReadingDirection(to direction: ReadingDirection) async throws {
    let context = moc

    try await context.perform {
      guard let manga = try self.mangaCrud.getManga(self.mangaId, moc: context) else {
        throw CrudError.mangaNotFound(id: self.mangaId)
      }

      self.mangaCrud.updateReadingDirection(manga, direction: direction)

      _ = try context.saveIfNeeded()
    }
  }

}

// MARK: Actions
extension ChapterReaderViewModel {

  func prepareDatasource() async {
    await datasource.prepareDatasource()
  }

  func onPageTask(_ pageId: String) async {
    let context = moc
    let pageIndex = pages
      .filter { !$0.isTransition }
      .firstIndex { $0.id == pageId }

    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.datasource.loadPagesIfNeeded(pageId)
      }

      taskGroup.addTask {
        try? await context.perform {
          guard
            let pageIndex,
            let chapter = try? self.chapterCrud.getChapter(
              self.chapter.id,
              moc: context
            )
          else {
            return
          }

          self.chapterCrud.updateLastPageRead(chapter, lastPageRead: pageIndex)

          if pageIndex >= self.pagesCount - 1 {
            self.chapterCrud.updateIsRead(chapter, isRead: true)
          }

          // TODO: Save when important, not in each page
          _ = try context.saveIfNeeded()
        }
      }
    }
  }

  func changeReadingDirection(to direction: ReadingDirection) async {
    await MainActor.run { readingDirection = direction }

    do {
      try await updateReadingDirection(to: direction)
    } catch {
      return
    }
  }

  func reloadPages(startingAt page: PageModel) async {
    guard let i = pages.firstIndex(where: { $0.id == page.id }) else { return }

    let j = min(i + 10, pages.count)
    let pages = pages[i..<j].compactMap {
      switch $0 {
      case .page(let page):
        return page

      default:
        return nil
      }
    }.compactMap {
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

// MARK: Transition Actions
extension ChapterReaderViewModel {

  func onTransitionAction(_ action: TransitionPageView.Action) {
    switch action {
    case .moveToNext:
      onMoveToNext()

    case .moveToPrevious:
      onMoveToPrevious()

    case .close:
      closeReaderEvent.send()
    }
  }

  private func onMoveToNext() {
    guard let nextChapter else {
      return
    }

    print("ChapterReadViewModel -> Moving to the next chapter")

    datasource = PagesDatasource(
      mangaId: mangaId,
      chapter: nextChapter,
      delegate: delegate,
      appOptionsStore: appOptionsStore
    )

    chapter = nextChapter
    resetViewModel(prepareDatasource: true)
  }

  private func onMoveToPrevious() {
    guard let previousChapter else {
      return
    }

    print("ChapterReadViewModel -> Moving to the previous chapter")

    datasource = PagesDatasource(
      mangaId: mangaId,
      chapter: previousChapter,
      delegate: delegate,
      appOptionsStore: appOptionsStore
    )

    chapter = previousChapter
    resetViewModel(prepareDatasource: true)
  }

}

// MARK: Helpers
extension ChapterReaderViewModel {

  var pagesCount: Int {
    return pages
      .filter { !$0.isTransition }
      .count
  }

  var selectedPageNumber: Int {
    guard let pageId else { return 0 }

    let page = pages.first { $0.id == pageId }

    switch page {
    case .page:
      return (pages
        .filter { !$0.isTransition }
        .map { $0.id }
        .firstIndex(of: pageId) ?? 0) + 1

    case .transition(let transition):
      switch transition {
      case .noNextChapter, .transitionToNext:
        return pagesCount

      case .noPreviousChapter, .transitionToPrevious:
        return 1
      }

    case nil:
      return 0
    }
  }

  private func makeStartTransitionPage() -> TransitionPageModel {
    if let previousChapter {
      return .transitionToPrevious(
        from: chapter.description,
        to: previousChapter.description,
        missingCount: missingPreviousChapters
      )
    }

    return .noPreviousChapter(currentChapter: chapter.description)
  }

  private func makeEndTransitionPage() -> TransitionPageModel {
    if let nextChapter {
      return .transitionToNext(
        from: chapter.description,
        to: nextChapter.description,
        missingCount: missingNextChapters
      )
    }

    return .noNextChapter(currentChapter: chapter.description)
  }

  private func setPages(_ pages: [PageModel]) {
    let start = [ChapterPage.transition(makeStartTransitionPage())]
    let end = [ChapterPage.transition(makeEndTransitionPage())]
    let pages = pages.map { ChapterPage.page($0) }

    self.pages = start + pages + end
  }

  private func updateTransitionPages(
    previous: TransitionPageModel,
    next: TransitionPageModel
  ) {
    let start = ChapterPage.transition(makeStartTransitionPage())
    let end = ChapterPage.transition(makeEndTransitionPage())

    let startIndex = pages.firstIndex {
      switch $0 {
      case .page:
        return false

      case .transition(let transition):
        switch transition {
        case .noNextChapter, .transitionToNext:
          return false

        case .noPreviousChapter, .transitionToPrevious:
          return true
        }
      }
    }

    let endIndex = pages.firstIndex {
      switch $0 {
      case .page:
        return false

      case .transition(let transition):
        switch transition {
        case .noNextChapter, .transitionToNext:
          return true

        case .noPreviousChapter, .transitionToPrevious:
          return false
        }
      }
    }

    if let startIndex {
      self.pages[startIndex] = start
    } else {
      self.pages.insert(start, at: 0)
    }

    if let endIndex {
      self.pages[endIndex] = end
    } else {
      self.pages.append(end)
    }
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
      pages[i] = .page(page)
    } else {
      pages.append(.page(page))
    }
  }

  private func calculateMissingChapters(
    from currentChapter: Double?,
    to nextChapter: Double?
  ) -> Int {
    guard
      let currentChapter,
      let nextChapter,
      nextChapter >= currentChapter
    else {
      return 0
    }

    let isNextChapterMain = nextChapter.truncatingRemainder(dividingBy: 1.0) == .zero
    let dif = Int(nextChapter) - Int(currentChapter)

    return isNextChapterMain ? dif - 1 : dif
  }

}
