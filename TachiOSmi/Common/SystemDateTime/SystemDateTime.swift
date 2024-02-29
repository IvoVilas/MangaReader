//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import SwiftDate

public final class SystemDateTime: SystemDateTimeType {

  private let clock: SystemClockType

  public let comparator: SystemDateTimeComparatorType
  public let builder: SystemDateTimeBuilderType
  public let rounder: SystemDateTimeRounderType
  public let calculator: SystemDateTimeCalculatorType
  public let interval: SystemDateTimeIntervalType

  public let startOf1970: Date = Date { component in
    component.year = 1970
    component.month = 1
    component.day = 1
    component.hour = 0
    component.minute = 0
    component.second = 0
  } ?? Date()

  public var startOfToday: Date {
    return now.startOfDay
  }

  public var now: Date {
    return clock.now
  }

  public var endOfToday: Date {
    return now.endOfDay
  }

  public var distantPast: Date {
    return Date.distantPast
  }

  public var distantFuture: Date {
    return Date.distantFuture
  }

  public init() {
    self.clock      = SystemClock()
    self.comparator = SystemDateTimeComparator(clock: clock)
    self.calculator = SystemDateTimeCalculator()
    self.builder    = SystemDateTimeBuilder(calculator: calculator)
    self.rounder    = SystemDateTimeRounder()
    self.interval   = SystemDateTimeInterval(
      clock: clock,
      calculator: calculator,
      comparator: comparator,
      builder: builder
    )
  }

  public init(
    clock: SystemClockType
  ) {
    self.clock      = clock
    self.comparator = SystemDateTimeComparator(clock: clock)
    self.calculator = SystemDateTimeCalculator()
    self.builder    = SystemDateTimeBuilder(calculator: calculator)
    self.rounder    = SystemDateTimeRounder()
    self.interval   = SystemDateTimeInterval(
      clock: clock,
      calculator: calculator,
      comparator: comparator,
      builder: builder
    )
  }

  public init(
    clock: SystemClockType,
    comparator: SystemDateTimeComparatorType,
    builder: SystemDateTimeBuilderType,
    rounder: SystemDateTimeRounderType,
    calculator: SystemDateTimeCalculatorType,
    interval: SystemDateTimeIntervalType
  ) {
    self.clock      = clock
    self.comparator = comparator
    self.builder    = builder
    self.rounder    = rounder
    self.calculator = calculator
    self.interval   = interval
  }

}
