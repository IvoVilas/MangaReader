//
//  MangaSources.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import CoreData
import UIKit

enum Source: Identifiable {

  case mangadex
  case manganelo
  case unknown

  static func allSources() -> [Source] {
    [.mangadex, .manganelo]
  }

  static func safeInit(from id: String) -> Source {
    switch id {
    case Source.mangadex.id:
      return .mangadex

    case Source.manganelo.id:
      return .manganelo

    default:
      return .unknown
    }
  }

  var id: String {
    switch self {
    case .mangadex:
      return "0"

    case .manganelo:
      return "1"

    case .unknown:
      return "-1"
    }
  }

  var name: String {
    switch self {
    case .mangadex, .unknown:
      return "MangaDex"

    case .manganelo:
      return "MangaNelo"
    }
  }

  var logo: UIImage {
    switch self {
    case .mangadex, .unknown:
      return .mangadex

    case .manganelo:
      return .manganelo
    }
  }

  var searchDelegateType: SearchDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexSearchDelegate.self

    case .manganelo:
      return ManganeloSearchDelegate.self

    case .unknown:
      return MockSearchDelegate.self
    }
  }

  var detailsDelegateType: DetailsDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexDetailsDelegate.self

    case .manganelo:
      return ManganeloDetailsDelegate.self

    case .unknown:
      return MockDetailsDelegate.self
    }
  }

  var chaptersDelegateType: ChaptersDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexChaptersDelegate.self

    case .manganelo:
      return ManganeloChaptersDelegate.self

    case .unknown:
      return MockChaptersDelegate.self
    }
  }

  var pagesDelegateType: PagesDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexPagesDelegate.self

    case .manganelo:
      return ManganeloPagesDelegate.self

    case .unknown:
      return MangadexPagesDelegate.self // TODO: Make mock pages
    }
  }

}
