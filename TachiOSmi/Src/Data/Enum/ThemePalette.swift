//
//  ThemePalette.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 18/05/2024.
//

import Foundation

enum ThemePalette: Identifiable {

  case system
  case light
  case dark

  var id: Int16 {
    switch self {
    case .system:
      return 1

    case .light:
      return 2

    case .dark:
      return 3

    }
  }

  static func safeInit(
    from id: Int16
  ) -> ThemePalette {
    switch id {
    case 2:
      return .light

    case 3:
      return .dark

    default:
      return .system
    }
  }

}
