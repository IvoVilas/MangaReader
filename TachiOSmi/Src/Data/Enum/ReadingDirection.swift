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
