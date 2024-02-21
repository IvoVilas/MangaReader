//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import SwiftDate

public final class SystemDateTimeRounder: SystemDateTimeRounderType {

  public init() { }

  public func roundDateToMinsCeil(_ date: Date) -> Date {
    let seconds = date.second

    if seconds == 0 {
      return date
    }

    let remaining = 60 - seconds

    return date + remaining.seconds
  }

  public func roundDateToMinsFloor(_ date: Date) -> Date {
    let seconds = date.second

    if seconds == 0 {
      return date
    }

    return date - seconds.seconds
  }

}
