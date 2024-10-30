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

  private let provider: MangaUpdatesProvider

  private var logsPage: Int

  private var observer: AnyCancellable?

  init(
    provider: MangaUpdatesProvider
  ) {
    self.provider = provider

    logs = []
    logsPage = 0

    observer = provider.$updateLogs
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.logs = $0 }
  }

  func loadMoreLogs() {
    logsPage += 1

    provider.updatePublishedValue(withPage: logsPage)
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
      jumpToPage: nil,
      chapter: log.chapter,
      readingDirection: log.manga.readingDirection
    )
  }

}
