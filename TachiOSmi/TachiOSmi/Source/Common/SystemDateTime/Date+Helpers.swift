//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

extension Date {

  public static func isToday(date: Date?) -> Bool {
    // If the date hasn't value something went wrong on the first login, so isToday should be true
    guard let date = date else { return true }

    return Calendar.current.isDateInToday(date)
  }

  public static func isIntervalAlreadyPassedInDays(
    initialDate: Date?,
    numberOfDays: Int
  ) -> Bool {
    guard let date = initialDate else { return true }

    let now                      = Date()
    let calendar                 = Calendar.current
    let numberOfDaysOnInterval   = calendar.dateComponents([.day], from: date, to: now)

    guard let days = numberOfDaysOnInterval.day else { return true }

    return days >= numberOfDays
  }

  public var startOfDay: Date {
    return Calendar.current.startOfDay(for: self)
  }

  public var endOfDay: Date {
    var components    = DateComponents()
    components.day    = 1
    components.second = -1

    return Calendar.current.date(byAdding: components, to: startOfDay)!
  }

}

#if DEV_TOOLS

extension Date {

  private static let debugDateTimeFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "dd-MM-yyyy hh:mm:ss"

    return dateFormatter
  }()

  private static let debugDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "dd-MM-yyyy"

    return dateFormatter
  }()

  private static let debugTimeFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "hh:mm:ss"

    return dateFormatter
  }()

  public func debugDateTimeString() -> String {
    return Date.debugDateTimeFormatter.string(from: self)
  }

  public func debugDateString() -> String {
    return Date.debugDateFormatter.string(from: self)
  }

  public func debugTimeString() -> String {
    return Date.debugTimeFormatter.string(from: self)
  }

}

#endif
