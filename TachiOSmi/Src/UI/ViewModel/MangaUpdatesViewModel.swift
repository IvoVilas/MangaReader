//
//  MangaUpdatesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 23/04/2024.
//

import Foundation
import SwiftUI
import CoreData
import Combine

struct MangaUpdateLogModel: Identifiable {

  var id: String { chapterId }

  let chapterId: String
  let mangaTitle: String
  let chapterTitle: String
  let publishDate: Date
  let lastPageRead: Int?
  let isRead: Bool
  let mangaCover: Data?

  var lastPageReadDescription: String? {
    if let lastPageRead {
      return "Page: \(lastPageRead + 1)"
    }

    return nil
  }

}

final class MangaUpdatesViewModel: ObservableObject {

  struct MangaUpdatesLogDate: Identifiable {

    var id: String { date.ISO8601Format() }

    let date: Date
    let logs: [MangaUpdateLogModel]

    // TODO: Why use date.month == today.month? If today is the 1st, the condition fails
    var dateDescription: String {
      let calendar = Calendar.current

      let today = calendar.dateComponents([.year, .month, .day], from: Date())
      let date  = calendar.dateComponents([.year, .month, .day], from: date)

      if
        date.year == today.year,
        date.month == today.month,
        date.day == today.day
      {
        return "Today"
      }

      if
        let day = today.day,
        date.year == today.year,
        date.month == today.month,
        date.day == day + 1
      {
        return "Yesterday"
      }

      if
        let todayDay = today.day,
        let dateDay = date.day,
        date.year == today.year,
        date.month == today.month,
        todayDay <= dateDay + 7
      {
        return "\(todayDay - dateDay) days ago"
      }

      let formatter = DateFormatter()

      formatter.dateStyle = .medium
      formatter.timeStyle = .none

      return formatter.string(from: self.date)
    }

  }

  @Published var logs: [MangaUpdatesLogDate]
  @Published var isLoading: Bool

  private let datasource: MangaUpdatesDatasource
  private let systemDateTime: SystemDateTimeType
  private let refreshLibraryUseCase: RefreshLibraryUseCase

  private var observers = Set<AnyCancellable>()

  init(
    coverCrud: CoverCrud,
    chapterCrud: ChapterCrud,
    refreshLibraryUseCase: RefreshLibraryUseCase,
    systemDateTime: SystemDateTimeType,
    viewMoc: NSManagedObjectContext
  ) {
    self.logs = []
    self.isLoading = false
    self.systemDateTime = systemDateTime
    self.refreshLibraryUseCase = refreshLibraryUseCase
    self.datasource = MangaUpdatesDatasource(
      coverCrud: coverCrud,
      chapterCrud: chapterCrud,
      systemDateTime: systemDateTime,
      viewMoc: viewMoc
    )

    datasource
      .logsPublisher
      .map { [weak self] (logs) -> [Date: [MangaUpdateLogModel]] in
        guard let self else { return [:] }

        return Dictionary(grouping: logs) {
          self.systemDateTime.calculator.getStartOfDay($0.publishDate)
        }
      }
      .map { logs in
        logs.map {
          MangaUpdatesLogDate(date: $0.key, logs: $0.value)
        }
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] values in
        guard let self else { return }

        self.logs = values.sorted { $0.date > $1.date }
      }
      .store(in: &observers)
  }

  func fetchNextLogs() async {
    await datasource.fetchNextUpdateLogs()
  }

  func refreshLibrary() async {
    await MainActor.run { isLoading = true }

    await refreshLibraryUseCase.refresh()

    await MainActor.run { isLoading = false }
  }


}
