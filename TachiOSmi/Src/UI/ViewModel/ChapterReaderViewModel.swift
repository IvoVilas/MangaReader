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

  private let datasource: PagesDatasource

  private var observers = Set<AnyCancellable>()

  init(
    datasource: PagesDatasource
  ) {
    self.datasource = datasource

    pages = []
    pagesCount = 0
    pageId = nil
    isLoading = false
    error = nil

    datasource.pagesPublisher
      .debounce(for: 0.3, scheduler: DispatchQueue.main)
      .sink { [weak self] in 
        self?.pages = $0
        self?.pagesCount = $0.count
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

}

extension ChapterReaderViewModel {

  func moveToPage(_ pos: Int) {
    if pages.indices.contains(pos) {
      Task(priority: .medium) {
        await datasource.loadPages(until: pos)
      }
    }
  }

  func fetchPages() async {
    await datasource.loadChapter()
  }

  func loadNextIfNeeded(_ pageId: String) async {
    await datasource.loadNextPagesIfNeeded(pageId)
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
