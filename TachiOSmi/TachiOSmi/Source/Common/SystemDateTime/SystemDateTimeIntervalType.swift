//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

public protocol SystemDateTimeIntervalType {

  func getPastFutureInterval() -> (startDate: Date, endDate: Date)
  func getPreviousDaysInterval(_ days: Int, date: Date) -> (startDate: Date, endDate: Date)
  func getPreviousWeeksInterval(_ weeks: Int) -> (startDate: Date, endDate: Date)
  func getPreviousMonthsInterval(_ months: Int) -> (startDate: Date, endDate: Date)
  func getPreviousYearsInterval(_ years: Int) -> (startDate: Date, endDate: Date)

  /// Generate random date respecting the interval and the today date
  /// - Parameters:
  ///   - interval: hours interval, from hour or current time if current time is bigger than from hour
  ///   - today: date to be used
  /// - Returns: nil if no date can be build
  func generateRandomDateInsideInterval(
    _ interval: (fromHour: Int, toHour: Int),
    respectingTodayDate today: Date
  ) -> Date?

}
