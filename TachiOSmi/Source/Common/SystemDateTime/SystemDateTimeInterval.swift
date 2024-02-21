//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//
import Foundation
import SwiftDate

public final class SystemDateTimeInterval: SystemDateTimeIntervalType {

  private let clock: SystemClockType
  private let calculator: SystemDateTimeCalculatorType
  private let comparator: SystemDateTimeComparatorType
  private let builder: SystemDateTimeBuilderType

  public init(
    clock: SystemClockType,
    calculator: SystemDateTimeCalculatorType,
    comparator: SystemDateTimeComparatorType,
    builder: SystemDateTimeBuilderType
  ) {
    self.clock      = clock
    self.calculator = calculator
    self.comparator = comparator
    self.builder    = builder
  }

  public func getPastFutureInterval() -> (startDate: Date, endDate: Date) {
    return (startDate: .distantPast, endDate: .distantFuture)
  }

  public func getPreviousDaysInterval(_ days: Int, date: Date) -> (startDate: Date, endDate: Date) {
    let startDate = calculator.getStartOfDay(date)
    let endDate   = calculator.removeDays(days, to: startDate)

    return (startDate: startDate, endDate: endDate)
  }

  public func getPreviousWeeksInterval(_ weeks: Int) -> (startDate: Date, endDate: Date) {
    let currentDate = calculator.removeWeeks(weeks, to: clock.now)
    let startDate   = calculator.getStartOfWeek(currentDate)
    let endOfYear   = calculator.getEndOfWeek(currentDate)

    return (startDate: startDate, endDate: endOfYear)
  }

  public func getPreviousMonthsInterval(_ months: Int) -> (startDate: Date, endDate: Date) {
    let currentDate = calculator.removeMonths(months, to: clock.now)
    let startDate   = calculator.getStartOfMonth(currentDate)
    let endOfYear   = calculator.getEndOfMonth(currentDate)

    return (startDate: startDate, endDate: endOfYear)
  }

  public func getPreviousYearsInterval(_ years: Int) -> (startDate: Date, endDate: Date) {
    let currentDate = calculator.removeYears(years, to: clock.now)
    let startDate   = calculator.getStartOfYear(currentDate)
    let endOfYear   = calculator.getEndOfYear(currentDate)

    return (startDate: startDate, endDate: endOfYear)
  }

  /// Generate random date respecting the interval and the today date
  /// - Parameters:
  ///   - interval: hours interval, from hour or current time if current time is bigger than from hour
  ///   - today: date to be used
  /// - Returns: nil if no date can be build
  public func generateRandomDateInsideInterval(
    _ interval: (fromHour: Int, toHour: Int),
    respectingTodayDate today: Date
  ) -> Date? {
    let endDate = builder.makeDateFromDate(
      today,
      hour: interval.toHour,
      minute: 0,
      second: 0
    )

    guard comparator.isDate(today, lessThan: endDate) else {
      return nil
    }

    let intervalBeginDate = builder.makeDateFromDate(
      today,
      hour: interval.fromHour,
      minute: 0,
      second: 0
    )

    let beginDate: Date

    if comparator.isDate(today, greaterThan: intervalBeginDate) {
      beginDate = today
    } else {
      beginDate = intervalBeginDate
    }

    let minutesBetweenDates   = calculator.numberOfMinutesBetweenDates(beginDate, endDate)
    let randomNumberOfMinutes = Int.random(in: 0...minutesBetweenDates)

    return calculator.addMinutes(randomNumberOfMinutes, to: beginDate)
  }

}
