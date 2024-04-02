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
  private let httpClient: HttpClient
  private let viewMoc: NSManagedObjectContext

  let closeReaderEvent = PassthroughSubject<Void, Never>()
  private let changedChapter: PassthroughSubject<ChapterModel, Never>
  private let changedReadingDirection: PassthroughSubject<ReadingDirection, Never>
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
    httpClient: HttpClient,
    changedChapter: PassthroughSubject<ChapterModel, Never>,
    changedReadingDirection: PassthroughSubject<ReadingDirection, Never>,
    viewMoc: NSManagedObjectContext
  ) {
    self.source = source
    self.mangaId = mangaId
    self.mangaTitle = mangaTitle
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.httpClient = httpClient
    self.changedChapter = changedChapter
    self.changedReadingDirection = changedReadingDirection
    self.viewMoc = viewMoc

    delegate = source.pagesDelegateType.init(httpClient: httpClient)
    datasource = PagesDatasource(
      chapter: chapter,
      delegate: delegate
    )

    self.pages = []
    self.pageId = nil
    self.chapter = chapter
    self.readingDirection = readingDirection
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
    Task.detached {
      await self.fetchAdjacentChapters()

      if prepareDatasource {
        await self.datasource.prepareDatasource()
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

        Task(priority: .userInitiated) {
          await self.setPages(pages)

          self.receivedPagesEvent.value = true

          var pageId: String?
          let firstId = pages.first?.id

          if self.chapter.isRead {
            pageId = firstId
          } else {
            pageId = pages.safeGet(self.chapter.lastPageRead)?.id ?? firstId
          }

          await MainActor.run { [pageId] in
            if self.pageId == nil {
              self.pageId = pageId
            }
          }
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
    let (next, previous) = await viewMoc.perform {
      let next = try? self.chapterCrud.findNextChapter(
        self.chapter.id,
        mangaId: self.mangaId,
        moc: self.viewMoc
      )

      let previous = try? self.chapterCrud.findPreviousChapter(
        self.chapter.id,
        mangaId: self.mangaId,
        moc: self.viewMoc
      )

      return (next, previous)
    }

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

    await updateTransitionPages(
      previous: makeEndTransitionPage(),
      next: makeStartTransitionPage()
    )
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

  func prepareDatasource() async {
    await datasource.prepareDatasource()
  }

  func onPageTask(_ pageId: String) async {
    let pageIndex = pages
      .filter { !$0.isTransition }
      .firstIndex { $0.id == pageId }

    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        await self.datasource.loadPagesIfNeeded(pageId)
      }

      taskGroup.addTask {
        await self.viewMoc.perform {
          guard
            let pageIndex,
            let chapter = try? self.chapterCrud.getChapter(
              self.chapter.id,
              moc: self.viewMoc
            )
          else {
            return
          }

          self.chapterCrud.updateLastPageRead(chapter, lastPageRead: pageIndex)
          self.chapterCrud.updateIsRead(chapter, isRead: pageIndex >= self.pagesCount - 1)

          switch self.viewMoc.saveIfNeeded(rollbackOnError: true) {
          case .success:
            self.changedChapter.send(.from(chapter))

          default:
            break
          }
        }
      }
    }
  }

  func changeReadingDirection(to direction: ReadingDirection) async {
    await MainActor.run { readingDirection = direction }

    do {
      try await updateReadingDirection(to: direction)

      // TODO: Implement
      // changedReadingDirection.send(direction)
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
      chapter: nextChapter,
      delegate: delegate
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
      chapter: previousChapter,
      delegate: delegate
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

  private func setPages(_ pages: [PageModel]) async {
    let start = [ChapterPage.transition(makeStartTransitionPage())]
    let end = [ChapterPage.transition(makeEndTransitionPage())]
    let pages = pages.map { ChapterPage.page($0) }

    await MainActor.run {
      self.pages = start + pages + end
    }
  }

  private func updateTransitionPages(
    previous: TransitionPageModel,
    next: TransitionPageModel
  ) async {
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
      await MainActor.run {
        self.pages[startIndex] = start
      }
    } else {
      await MainActor.run {
        self.pages.insert(start, at: 0)
      }
    }

    if let endIndex {
      await MainActor.run {
        self.pages[endIndex] = end
      }
    } else {
      await MainActor.run {
        self.pages.append(end)
      }
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

}

