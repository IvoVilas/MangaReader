//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//
import Foundation
import SwiftDate

public final class SystemDateTimeComparator: SystemDateTimeComparatorType {

  private let clock: SystemClockType

  public var isYesterday: Bool {
    return clock.now.isYesterday
  }

  public var isToday: Bool {
    return clock.now.isToday
  }

  public var isTomorrow: Bool {
    return clock.now.isTomorrow
  }

  public init(clock: SystemClockType) {
    self.clock = clock
  }

  public func isDateYesterday(_ date: Date) -> Bool {
    return date.isYesterday
  }

  public func isDateToday(_ date: Date) -> Bool {
    return date.isToday
  }

  public func isDateTomorrow(_ date: Date) -> Bool {
    return date.isTomorrow
  }

  public func isDate(_ date: Date, lessThan other: Date) -> Bool {
    return date < other
  }
  
  public func isDate(_ date: Date, lessThanOrEqual other: Date) -> Bool {
    return date <= other
  }
  
  public func isDate(_ date: Date, greaterThan other: Date) -> Bool {
    return date > other
  }
  
  public func isDate(_ date: Date, greaterThanOrEqual other: Date) -> Bool {
    return date >= other
  }

  public func isDate(_ date: Date, greaterThan lowerDate: Date, andLessThan upperDate: Date) -> Bool {
    return date > lowerDate && date < upperDate
  }
  
  public func isDate(_ date: Date, greaterThanOrEqual lowerDate: Date, andLessThanOrEqual upperDate: Date) -> Bool {
    return date >= lowerDate && date <= upperDate
  }

  public func isDate(_ date: Date, inSameDayAs otherDate: Date) -> Bool {
    return Calendar.current.isDate(date, inSameDayAs: otherDate)
  }

}
