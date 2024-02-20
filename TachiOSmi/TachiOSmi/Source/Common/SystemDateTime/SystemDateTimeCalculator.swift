//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import SwiftDate

public final class SystemDateTimeCalculator: SystemDateTimeCalculatorType {

  public init() { }

  public func dateToInt(_ date: Date) -> Int {
    let dateComponents = getDateComponents(date)

    // Example: year = 2023, month = 4, day = 2
    // 2023 * 100   = 202300
    // 202300 + 4   = 202304
    // 202304 * 100 = 20230400
    // 202304 + 2   = 20230402

    let yearWithMonth = (dateComponents.year * 100) + dateComponents.month
    let yearWithMonthAndDay = (yearWithMonth * 100) + dateComponents.day

    return yearWithMonthAndDay
  }

  public func getDateComponents(_ date: Date) -> (year: Int, month: Int, day: Int) {
    let calendar   = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day], from: date)

    guard
      let year = components.year,
      let month = components.month,
      let day = components.day
    else {
      return (year: 1970, month: 1, day: 1)
    }

    return (year: year, month: month, day: day)
  }

  public func getTimeComponents(_ date: Date) -> (hour: Int, minute: Int, second: Int) {
    let calendar   = Calendar.current
    let components = calendar.dateComponents([.hour, .minute, .second], from: date)

    guard
      let hour = components.hour,
      let minute = components.minute,
      let second = components.second
    else {
      return (hour: 1, minute: 0, second: 0)
    }

    return (hour: hour, minute: minute, second: second)
  }

  public func getStartOfDay(_ date: Date) -> Date {
    return date.startOfDay
  }

  public func getEndOfDay(_ date: Date) -> Date {
    return date.endOfDay
  }

  public func getStartOfWeek(_ date: Date) -> Date {
    return date.dateAtStartOf([.weekOfYear, .hour, .minute, .second, .nanosecond])
  }

  public func getEndOfWeek(_ date: Date) -> Date {
    return date.dateAtEndOf([.weekOfYear, .hour, .minute, .second, .nanosecond])
  }

  public func getStartOfMonth(_ date: Date) -> Date {
    return date.dateAtStartOf([.month, .day, .hour, .minute, .second, .nanosecond])
  }

  public func getEndOfMonth(_ date: Date) -> Date {
    return date.dateAtEndOf([.month, .day, .hour, .minute, .second, .nanosecond])
  }

  public func getStartOfYear(_ date: Date) -> Date {
    return date.dateAtStartOf([.year, .month, .day, .hour, .minute, .second, .nanosecond])
  }

  public func getEndOfYear(_ date: Date) -> Date {
    return date.dateAtEndOf([.year, .month, .day, .hour, .minute, .second, .nanosecond])
  }

  public func getDayOfWeek(_ date: Date) -> Int {
    return date.weekday
  }

  public func addSeconds(_ seconds: Int, to date: Date) -> Date {
    return date + seconds.seconds
  }

  public func addMinutes(_ minutes: Int, to date: Date) -> Date {
    return date + minutes.minutes
  }

  public func addHours(_ hours: Int, to date: Date) -> Date {
    return date + hours.hours
  }

  public func addDays(_ days: Int, to date: Date) -> Date {
    return date + days.days
  }

  public func addWeeks(_ weeks: Int, to date: Date) -> Date {
    return date + weeks.weeks
  }

  public func addMonths(_ months: Int, to date: Date) -> Date {
    return date + months.months
  }

  public func addYears(_ years: Int, to date: Date) -> Date {
    return date + years.years
  }

  public func removeSeconds(_ seconds: Int, to date: Date) -> Date {
    if seconds == 0 {
      return date
    }

    return date - seconds.seconds
  }

  public func removeMinutes(_ minutes: Int, to date: Date) -> Date {
    if minutes == 0 {
      return date
    }

    return date - minutes.minutes
  }

  public func removeHours(_ hours: Int, to date: Date) -> Date {
    if hours == 0 {
      return date
    }

    return date - hours.hours
  }

  public func removeDays(_ days: Int, to date: Date) -> Date {
    if days == 0 {
      return date
    }

    return date - days.days
  }

  public func removeWeeks(_ weeks: Int, to date: Date) -> Date {
    if weeks == 0 {
      return date
    }

    return date - weeks.weeks
  }

  public func removeMonths(_ months: Int, to date: Date) -> Date {
    if months == 0 {
      return date
    }

    return date - months.months
  }

  public func removeYears(_ years: Int, to date: Date) -> Date {
    if years == 0 {
      return date
    }

    return date - years.years
  }

  public func numberOfMinutesSinceMidnight(_ date: Date) -> Int {
    let components = date.calendar.dateComponents([.hour, .minute], from: date)

    return (60 * (components.hour ?? 0)) + (components.minute ?? 0)
  }
  
  public func numberOfMinutesBetweenDates(_ from: Date, _ to: Date) -> Int {
    let calendar                  = Calendar.current
    let numberOfMinutesOnInterval = calendar.dateComponents([.minute], from: from, to: to)

    return numberOfMinutesOnInterval.minute ?? 0
  }

  public func numberOfDaysBetweenDates(_ from: Date, _ to: Date) -> Int {
    let fromDate = from.startOfDay
    let toDate   = to.startOfDay

    let calendar               = Calendar.current
    let numberOfDaysOnInterval = calendar.dateComponents([.day], from: fromDate, to: toDate)

    return numberOfDaysOnInterval.day ?? 0
  }

  public func numberOfMonthsBetweenDates(_ from: Date, _ to: Date) -> Int {
    let fromDate = from.startOfDay
    let toDate   = to.startOfDay

    let calendar               = Calendar.current
    let numberOfDaysOnInterval = calendar.dateComponents([.month], from: fromDate, to: toDate)

    return numberOfDaysOnInterval.month ?? 0
  }

  public func numberOfYearsBetweenDates(_ from: Date, _ to: Date) -> Int {
    let fromDate = from.startOfDay
    let toDate   = to.startOfDay

    let calendar                = Calendar.current
    let numberOfYearsOnInterval = calendar.dateComponents([.year], from: fromDate, to: toDate)

    return numberOfYearsOnInterval.year ?? 0
  }

  public func nextDateThatMatchesWeekDay(
    _ weekDay: Int,
    after: Date
  ) -> Date {
    let calendar   = Calendar.current
    var components = DateComponents()

    components.weekday = weekDay

    return calendar.nextDate(
      after: after,
      matching: components,
      matchingPolicy: .nextTime
    ) ?? after
  }
  
}
