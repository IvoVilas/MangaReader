//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

// GlobalDependency()
public protocol SystemDateTimeType {

  var comparator: SystemDateTimeComparatorType { get }
  var builder: SystemDateTimeBuilderType { get }
  var rounder: SystemDateTimeRounderType { get }
  var calculator: SystemDateTimeCalculatorType { get }
  var interval: SystemDateTimeIntervalType { get }

  var startOf1970: Date { get }
  var startOfToday: Date { get }
  var now: Date { get }
  var endOfToday: Date { get }

  var distantPast: Date { get }
  var distantFuture: Date { get }

}
