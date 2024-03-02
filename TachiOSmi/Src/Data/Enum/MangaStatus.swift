//
//  MangaStatus.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

enum MangaStatus {

  case completed
  case ongoing
  case cancelled
  case hiatus
  case unknown

  var id: Int16 {
    switch self {
    case .completed:
      return 0

    case .ongoing:
      return 1

    case .cancelled:
      return 2

    case .hiatus:
      return 3

    case .unknown:
      return -1
    }
  }

  var value: String {
    switch self {
    case .completed:
      return "completed"

    case .ongoing:
      return "ongoing"

    case .cancelled:
      return "cancelled"

    case .hiatus:
      return "hiatus"

    case .unknown:
      return "unknown"
    }
  }

  static func safeInit(from id: Int16) -> MangaStatus {
    switch id {
    case 0:
      return .completed

    case 1:
      return .ongoing

    case 2:
      return .cancelled

    case 3:
      return .hiatus

    default:
      return .unknown
    }
  }

  // TODO: Move to parser
  static func safeInit(from value: String) -> MangaStatus {
    switch value {
    case "completed":
      return .completed

    case "ongoing":
      return .ongoing

    case "cancelled":
      return .cancelled

    case "hiatus":
      return .hiatus

    default:
      return .unknown
    }
  }

}
