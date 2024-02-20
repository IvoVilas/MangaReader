//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//
import Foundation
import SwiftDate

public final class SystemDateTimeBuilder: SystemDateTimeBuilderType {

  private let calculator: SystemDateTimeCalculatorType

  public init(calculator: SystemDateTimeCalculatorType) {
    self.calculator = calculator
  }

  public func makeDate(day: Int, month: Int, year: Int) -> Date {
    return Date { component in
      component.year   = year
      component.month  = month
      component.day    = day
      component.hour   = 0
      component.minute = 0
      component.second = 0
    } ?? Date()
  }

  public func makeDateFromDate(_ date: Date, hour: Int, minute: Int, second: Int) -> Date {
    return Date { component in
      let dateComponents = calculator.getDateComponents(date)

      component.year   = dateComponents.year
      component.month  = dateComponents.month
      component.day    = dateComponents.day
      component.hour   = hour
      component.minute = minute
      component.second = second
    } ?? Date()
  }

  public func makeDateFromDate(_ date: Date, second: Int) -> Date {
    return Date { component in
      let dateComponents = calculator.getDateComponents(date)
      let timeComponents = calculator.getTimeComponents(date)

      component.year   = dateComponents.year
      component.month  = dateComponents.month
      component.day    = dateComponents.day
      component.hour   = timeComponents.hour
      component.minute = timeComponents.minute
      component.second = second
    } ?? Date()
  }

  public func calculateDates(
    startDate: Date,
    daysIntoThePast: Int
  ) -> [Date] {
    var dates = [Date]()

    for index in 0...daysIntoThePast {
      let date = calculator.getStartOfDay(
        calculator.removeDays(
          index,
          to: startDate
        )
      )

      dates.append(date)
    }

    return dates
  }

}
