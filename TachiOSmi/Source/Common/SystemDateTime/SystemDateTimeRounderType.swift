//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

public protocol SystemDateTimeRounderType {

  func roundDateToMinsCeil(_ date: Date) -> Date
  func roundDateToMinsFloor(_ date: Date) -> Date

}
