//
//  BackgroundManager.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 01/06/2024.
//

import Foundation
import BackgroundTasks

// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"Moguizan.TachiOSmi.background_task.library_refresh"]
final class BackgroundManager {

  private let refreshLibraryUseCase: RefreshLibraryUseCase
  private let systemDateTime: SystemDateTimeType

  init(
    refreshLibraryUseCase: RefreshLibraryUseCase,
    systemDateTime: SystemDateTimeType
  ) {
    self.refreshLibraryUseCase = refreshLibraryUseCase
    self.systemDateTime = systemDateTime
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

    print("BackgroundManager -> Starting library refresh...")
    await refreshLibraryUseCase.refresh()
    print("BackgroundManager -> Endend library refresh")
  }

}

// MARK: Helpers
extension BackgroundManager {

  private func calculateNextWeeklyRefreshDate() -> Date? {
    let calendar = Calendar.current
    let now = systemDateTime.now

    var components = DateComponents()
    components.weekday = 1
    components.hour = 20
    components.minute = 0
    components.second = 0

    return calendar.nextDate(
      after: now,
      matching: components,
      matchingPolicy: .nextTime
    )
  }

}
