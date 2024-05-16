//
//  MangaUpdatesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 23/04/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class MangaUpdatesViewModel: ObservableObject {

  @Published var logs: [MangaUpdatesProvider.MangaUpdatesLogDate]
  @Published var isLoading: Bool

  private let provider: MangaUpdatesProvider
  private let refreshLibraryUseCase: RefreshLibraryUseCase
  private let viewMoc: NSManagedObjectContext

  private var logsPage: Int

  private var observer: AnyCancellable?

  init(
    provider: MangaUpdatesProvider,
    refreshLibraryUseCase: RefreshLibraryUseCase,
    viewMoc: NSManagedObjectContext
  ) {
    self.provider = provider
    self.refreshLibraryUseCase = refreshLibraryUseCase
    self.viewMoc = viewMoc

    logs = []
    isLoading = false
    logsPage = 0

    observer = provider.$updateLogs
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.logs = $0 }
  }

  func loadMoreLogs() {
    logsPage += 1

    provider.updatePublishedValue(withPage: logsPage)
  }

  func refreshLibrary() async {
    await MainActor.run { isLoading = true }

    await refreshLibraryUseCase.refresh()

    await MainActor.run { isLoading = false }
  }

}

extension MangaUpdatesViewModel {

  func getNavigator(
    _ log: MangaUpdatesProvider.MangaUpdateLogModel
  ) -> MangaReaderNavigator {
    return MangaReaderNavigator(
      source: log.manga.source,
      mangaId: log.manga.id,
      mangaTitle: log.manga.title,
      chapter: log.chapter,
      readingDirection: log.manga.readingDirection,
      viewMoc: viewMoc
    )
  }

}
