//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

public protocol SystemDateTimeComparatorType {

  var isYesterday: Bool { get }
  var isToday: Bool { get }
  var isTomorrow: Bool { get }

  func isDateYesterday(_ date: Date) -> Bool
  func isDateToday(_ date: Date) -> Bool
  func isDateTomorrow(_ date: Date) -> Bool

  func isDate(_ date: Date, lessThan other: Date) -> Bool
  func isDate(_ date: Date, lessThanOrEqual other: Date) -> Bool
  func isDate(_ date: Date, greaterThan other: Date) -> Bool
  func isDate(_ date: Date, greaterThanOrEqual other: Date) -> Bool
  func isDate(_ date: Date, greaterThan lowerDate: Date, andLessThan upperDate: Date) -> Bool
  func isDate(_ date: Date, greaterThanOrEqual lowerDate: Date, andLessThanOrEqual upperDate: Date) -> Bool

  func isDate(_ date: Date, inSameDayAs otherDate: Date) -> Bool

}
