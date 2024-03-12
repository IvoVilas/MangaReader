//
//  ReadingDirection.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 08/03/2024.
//

import Foundation

enum ReadingDirection {

  case leftToRight
  case upToDown

  var id: Int16 {
    switch self {
    case .leftToRight:
      return 0

    case .upToDown:
      return 1
    }
  }

  var isHorizontal: Bool {
    switch self {
    case .leftToRight:
      return true

    case .upToDown:
      return false
    }
  }

  func toggle() -> ReadingDirection {
    switch self {
    case .leftToRight:
      return .upToDown

    case .upToDown:
      return .leftToRight
    }
  }

  static func safeInit(
    from id: Int16
  ) -> ReadingDirection {
    switch id {
    case 1:
      return .upToDown

    default:
      return .leftToRight
    }
  }

}
