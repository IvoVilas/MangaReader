//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

public protocol SystemDateTimeCalculatorType {

  func dateToInt(_ date: Date) -> Int

  func getDateComponents(_ date: Date) -> (year: Int, month: Int, day: Int)
  func getTimeComponents(_ date: Date) -> (hour: Int, minute: Int, second: Int)

  func getStartOfDay(_ date: Date) -> Date
  func getEndOfDay(_ date: Date) -> Date

  func getStartOfWeek(_ date: Date) -> Date
  func getEndOfWeek(_ date: Date) -> Date

  func getStartOfMonth(_ date: Date) -> Date
  func getEndOfMonth(_ date: Date) -> Date

  func getStartOfYear(_ date: Date) -> Date
  func getEndOfYear(_ date: Date) -> Date

  func getDayOfWeek(_ date: Date) -> Int

  func addSeconds(_ seconds: Int, to date: Date) -> Date
  func addMinutes(_ minutes: Int, to date: Date) -> Date
  func addHours(_ hours: Int, to date: Date) -> Date

  func addDays(_ days: Int, to date: Date) -> Date
  func addWeeks(_ weeks: Int, to date: Date) -> Date
  func addMonths(_ months: Int, to date: Date) -> Date
  func addYears(_ years: Int, to date: Date) -> Date

  func removeSeconds(_ seconds: Int, to date: Date) -> Date
  func removeMinutes(_ minutes: Int, to date: Date) -> Date
  func removeHours(_ hours: Int, to date: Date) -> Date

  func removeDays(_ days: Int, to date: Date) -> Date
  func removeWeeks(_ weeks: Int, to date: Date) -> Date
  func removeMonths(_ months: Int, to date: Date) -> Date
  func removeYears(_ years: Int, to date: Date) -> Date

  func numberOfMinutesSinceMidnight(_ date: Date) -> Int
  func numberOfMinutesBetweenDates(_ from: Date, _ to: Date) -> Int
  func numberOfDaysBetweenDates(_ from: Date, _ to: Date) -> Int
  func numberOfMonthsBetweenDates(_ from: Date, _ to: Date) -> Int
  func numberOfYearsBetweenDates(_ from: Date, _ to: Date) -> Int

  func nextDateThatMatchesWeekDay(_ weekDay: Int, after: Date) -> Date

}
