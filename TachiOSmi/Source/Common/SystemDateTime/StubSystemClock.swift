//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import SwiftDate

public final class StubSystemClock: SystemClockType {

  public var now: Date

  public init(now: Date) {
    self.now = now
  }

  public func goTo(_ date: Date) {
    now = date
  }

  public func advanceSeconds(_ value: Int) {
    now = now + value.seconds
  }

  public func advanceMinutes(_ value: Int) {
    now = now + value.minutes
  }

  public func advanceHours(_ value: Int) {
    now = now + value.hours
  }

  public func advanceDays(_ value: Int) {
    now = now + value.days
  }

}
