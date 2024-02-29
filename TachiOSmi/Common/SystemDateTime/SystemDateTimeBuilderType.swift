//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

public protocol SystemDateTimeBuilderType {

  func makeDate(day: Int, month: Int, year: Int) -> Date
  func makeDateFromDate(_ date: Date, hour: Int, minute: Int, second: Int) -> Date
  func makeDateFromDate(_ date: Date, second: Int) -> Date

  func calculateDates(
    startDate: Date,
    daysIntoThePast: Int
  ) -> [Date]

}
