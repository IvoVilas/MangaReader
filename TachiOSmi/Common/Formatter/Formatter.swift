//
//  Formatter.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation

final class Formatter {

  private let systemDateTime: SystemDateTimeType

  private let mediumDateFormater = Formatter.makeDateFormatter(
    dateStyle: .medium,
    timeStyle: .none
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
      return mediumDateFormater.string(from: date)
    }
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

}
