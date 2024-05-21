//
//  Formatter.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation

final class Formatter {

  private let systemDateTime: SystemDateTimeType

  private let mediumDateFormatter = Formatter.makeDateFormatter(
    dateStyle: .medium,
    timeStyle: .none
  )

  private let iso8601Formatter = Formatter.makeDateFormatter(
    format: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
  )

  init(systemDateTime: SystemDateTimeType) {
    self.systemDateTime = systemDateTime
  }

  func dateAsFriendlyFormat(_ date: Date) -> String {
    let numberOfDays = systemDateTime.calculator.numberOfDaysBetweenDates(date.endOfDay, systemDateTime.now.endOfDay)
    switch numberOfDays {
    case 0:
      return "Today"

    case 1:
      return "Yesterday"

    case 2...7:
      return "\(numberOfDays) days ago"

    default:
      return mediumDateFormatter.string(from: date)
    }
  }

  func dateAsISO8601(_ date: Date) -> String {
    return iso8601Formatter.string(from: date)
  }

  func dateFromISO8601(_ value: String) -> Date? {
    return iso8601Formatter.date(from: value)
  }

}

extension Formatter {

  static func makeDateFormatter(
    dateStyle: DateFormatter.Style,
    timeStyle: DateFormatter.Style
  ) -> DateFormatter {
    let dateFormatter = DateFormatter()

    dateFormatter.dateStyle = dateStyle
    dateFormatter.timeStyle = timeStyle

    return dateFormatter
  }

  static func makeDateFormatter(
    format: String
  ) -> DateFormatter {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = format

    return dateFormatter
  }

}
