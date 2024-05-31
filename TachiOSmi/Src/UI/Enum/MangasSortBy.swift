//
//  MangasSortBy.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 31/05/2024.
//

import Foundation

enum MangasSortBy {

  case title
  case totalChapters
  case unreadCount
  case latestChapter

  var description: String {
    switch self {
    case .title:
      return "Alphabetically"

    case .totalChapters:
      return "Total chapters count"

    case .unreadCount:
      return "Unread chapters count"

    case .latestChapter:
      return "Latests chapter release"
    }
  }

  var id: Int16 {
    switch self {
    case .title:
      return 1

    case .totalChapters:
      return 2

    case .unreadCount:
      return 3

    case .latestChapter:
      return 4
    }
  }

  static func safeInit(from id: Int16) -> MangasSortBy {
    switch id {
    case 2:
      return .totalChapters

    case 3:
      return .unreadCount

    case 4:
      return .latestChapter

    default:
      return .title
    }
  }

}
