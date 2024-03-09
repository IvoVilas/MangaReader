//
//  ChapterReaderViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import Foundation
import SwiftUI
import Combine

final class ChapterReaderViewModel: ObservableObject {

  @Published var pages: [PageModel]
  @Published var isLoading: Bool
  @Published var pagesCount: Int
  @Published var pageId: String?
  @Published var error: DatasourceError?

  private var datasource: PagesDatasource
  private var transitionDatasource: PagesDatasource?

  private let source: Source
  private var chapter: ChapterModel
  private let chapters: [ChapterModel]
  private let httpClient: HttpClient

  private var observers = Set<AnyCancellable>()
  private var transitionObservers = Set<AnyCancellable>()

  // TODO: Search for chapter in the database instead of keeping in memory
  init(
    source: Source,
    chapter: ChapterModel,
    chapters: [ChapterModel],
    httpClient: HttpClient
  ) {
    self.source = source
    self.chapter = chapter
    self.chapters = chapters
    self.httpClient = httpClient

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

    datasource.pagesPublisher
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] in
        guard let self else { return }

        if !$0.isEmpty {
          var pages = $0

          pages.append(.transition(chapterId))
          if let previousId = self.previousChapterId {
            pages.insert(.transition(previousId), at: 0)
          }

          self.updateOrAppend(pages)
          self.pagesCount = self.pagesBetweenTransitions().count

          if pageId == nil {
            pageId = $0.first?.id
          }
        }
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

  private func onTransitionPage() {
    guard
      let i = chapters.firstIndex(of: chapter),
      let nextChapter = chapters.safeGet(i - 1)
    else {
      return
    }

    print("ChapterReaderViewModel -> Entered transition page")
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
      await transitionDatasource.loadChapter()
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

}

// MARK: Actions
extension ChapterReaderViewModel {

  func fetchPages() async {
    await datasource.loadChapter()
  }

  func onPageTask(_ pageId: String) async {
    if pageId == pages.transitionPage(withId: chapterId)?.id {
      onTransitionPage()
    } else if pageId == pages.pageAfterTransition(withId: chapterId)?.id {
      onMoveToNext()
    } else {
      await datasource.loadNextPagesIfNeeded(pageId)
    }
  }

  func movedToPage(_ id: String) {
    Task(priority: .medium) {
      await datasource.loadPages(until: id)
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

// MARK: Useful helpers
extension ChapterReaderViewModel {

  var chapterId: String { chapter.id }

  var previousChapterId: String? {
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

}
