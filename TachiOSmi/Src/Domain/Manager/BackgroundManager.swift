//
//  BackgroundManager.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 01/06/2024.
//

import Foundation
import BackgroundTasks
import CoreData

final class BackgroundManager {

  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let chapterCrud: ChapterCrud
  private let refreshLibraryUseCase: RefreshLibraryUseCase
  private let notificationManager: NotificationManager
  private let systemDateTime: SystemDateTimeType
  private let viewMoc: NSManagedObjectContext

  init(
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    chapterCrud: ChapterCrud,
    refreshLibraryUseCase: RefreshLibraryUseCase,
    notificationManager: NotificationManager,
    systemDateTime: SystemDateTimeType,
    viewMoc: NSManagedObjectContext
  ) {
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.chapterCrud = chapterCrud
    self.refreshLibraryUseCase = refreshLibraryUseCase
    self.notificationManager = notificationManager
    self.systemDateTime = systemDateTime
    self.viewMoc = viewMoc
  }

  func scheduleLibraryRefresh() {
    let nextSunday = calculateNextWeeklyRefreshDate()

    let request = BGAppRefreshTaskRequest(identifier: AppTask.libraryRefresh.identifier)
    request.earliestBeginDate = nextSunday

    do {
      try BGTaskScheduler.shared.submit(request)

      print("BackgroundManager -> Scheduled library refresh to \(String(describing: nextSunday))")
    } catch {
      print("BackgroundManager -> Failed to schedule library refresh: \(error)")
    }
  }

  func handleLibraryRefresh() async {
    scheduleLibraryRefresh()

    print("BackgroundManager -> Starting background library refresh...")

    let updates = await refreshLibraryUseCase.refresh()

    await sendNewChaptersNotifications(using: updates)

    print("BackgroundManager -> Endend background library refresh")
  }

}

// MARK: Helpers
extension BackgroundManager {

  private func calculateNextWeeklyRefreshDate() -> Date? {
    let calendar = Calendar.current
    let now = systemDateTime.now

    var components = DateComponents()
    components.weekday = 1
    components.hour = 21
    components.minute = 0
    components.second = 0

    return calendar.nextDate(
      after: now,
      matching: components,
      matchingPolicy: .nextTime
    )
  }

  private func sendNewChaptersNotifications(
    using updates: [String: [String]]
  ) async {
    guard !updates.isEmpty else {
      notificationManager.scheduleNoNewChaptersNotification()

      return
    }

    for update in updates {
      let (id, chapters) = update
      let context = viewMoc

      if chapters.count <= 0 { continue }

      let manga = try? await context.perform { () -> MangaModel? in
        guard let manga = try self.mangaCrud.getManga(id, moc: context) else {
          return nil
        }

        let cover = try self.coverCrud.getCoverData(for: id, moc: context)

        return MangaModel.from(manga, cover: cover)
      }

      guard let manga else { continue }

      let body: NotificationManager.ChapterUpdate

      if chapters.count == 1 {
        let id = chapters[0]

        let description = await context.perform {
          let chapter = try? self.chapterCrud.getChapter(id, moc: context)

          guard let chapter else { return "" }

          return ChapterModel.from(chapter).simplifiedDescription
        }

        body = .single(description)
      } else {
        body = .multiple(update.value.count)
      }

      notificationManager.scheduleChapterNotification(
        for: manga,
        description: body
      )
    }
  }

}
