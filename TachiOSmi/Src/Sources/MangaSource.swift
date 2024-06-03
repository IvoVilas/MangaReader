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
  case mangafire
  case unknown

  static func allSources() -> [Source] {
    [.mangadex, .manganelo, .mangafire]
  }

  static func safeInit(from id: String) -> Source {
    switch id {
    case Source.mangadex.id:
      return .mangadex

    case Source.manganelo.id:
      return .manganelo

    case Source.mangafire.id:
      return .mangafire

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

    case .mangafire:
      return "2"

    case .unknown:
      return "-1"
    }
  }

  var name: String {
    switch self {
    case .mangadex, .unknown:
      return "MangaDex"

    case .mangafire:
      return "MangaFire"

    case .manganelo:
      return "MangaNelo"
    }
  }

  // TODO: Return asset instead of image
  var logo: UIImage {
    switch self {
    case .mangadex, .unknown:
      return .mangadex

    case .manganelo:
      return .manganelo

    case .mangafire:
      return .mangafire
    }
  }

  var searchDelegateType: SearchDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexSearchDelegate.self

    case .manganelo:
      return ManganeloSearchDelegate.self

    case .mangafire:
      return MangafireSearchDelegate.self

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

    case .mangafire:
      return MangafireDetailsDeletage.self

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

    case .mangafire:
      return MangafireChaptersDelegate.self

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

    case .mangafire:
      return MangafirePagesDelegate.self

    case .unknown:
      return MangadexPagesDelegate.self // TODO: Make mock pages
    }
  }

}
