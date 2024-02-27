//
//  MangaReaderViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaReaderViewModel: ObservableObject {

  @Published var pages: [PageModel]
  @Published var isLoading: Bool
  @Published var error: DatasourceError?

  private let datasource: ChapterPagesDatasource

  private var observers = Set<AnyCancellable>()

  init(
    datasource: ChapterPagesDatasource
  ) {
    self.datasource = datasource

    pages     = []
    isLoading = false
    error     = nil

    datasource.pagesPublisher
      .debounce(for: 0.3, scheduler: DispatchQueue.main)
      .sink { [weak self] in self?.pages = $0 }
      .store(in: &observers)

    datasource.statePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.isLoading = $0.isLoading }
      .store(in: &observers)

    datasource.errorPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.error = $0 }
      .store(in: &observers)
  }

  func fetchPages() async {
    await datasource.refresh()
  }

  func loadNextIfNeeded(_ pageId: String) {
    let count = pages.count

    guard count - 3 >= 0 else {
      if pageId == pages.last?.id {
        Task(priority: .background) {
          await datasource.loadNextPages()
        }
      }

      return
    }

    if pageId == pages[count - 3].id {
      Task(priority: .background) {
        await datasource.loadNextPages()
      }
    }
  }

}
