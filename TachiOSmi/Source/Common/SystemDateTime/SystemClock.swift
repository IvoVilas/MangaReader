//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

public struct SystemClock: SystemClockType {

  public var now: Date {
    return Date()
  }

  public init() { }

}
