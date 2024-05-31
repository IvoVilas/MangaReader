//
//  CollectionLayout.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import Foundation

enum CollectionLayout {
  
  case normal
  case compact
  case list

  var id: Int16 {
    switch self {
    case .normal:
      return 1
    case .compact:
      return 2
    case .list:
      return 3
    }
  }

  var icon: IconSource {
    switch self {
    case .normal:
      return .system("rectangle.grid.3x2.fill")
    case .compact:
      return .system("square.grid.3x3.fill")

    case .list:
      return .system("list.dash")
    }
  }

  var name: String {
    switch self {
    case .normal:
      return "Normal Grid"
    case .compact:
      return "Compact Grid"
    case .list:
      return "List"
    }
  }

  var isGrid: Bool {
    switch self {
    case .normal, .compact:
      return true
    case .list:
      return false
    }
  }

  var isList: Bool {
    switch self {
    case .normal, .compact:
      return false
    case .list:
      return true
    }
  }

  static func safeInit(from id: Int16) -> CollectionLayout {
    switch id {
    case 2:
      return .compact

    case 3:
      return .list

    default:
      return .normal
    }
  }

}
