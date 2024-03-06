//
//  MangaSources.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import CoreData
import UIKit

enum Source {

  case mangadex
  case manganelo

  var name: String {
    switch self {
    case .mangadex:
      return "MangaDex"

    case .manganelo:
      return "MangaNelo"
    }
  }

  var id: String {
    switch self {
    case .mangadex:
      return "0"

    case .manganelo:
      return "1"
    }
  }

  var logo: UIImage {
    switch self {
    case .mangadex:
      return .mangadex

    case .manganelo:
      return .manganelo
    }
  }

  var viewMoc: NSManagedObjectContext {
    switch self {
    case .mangadex:
      return PersistenceController.shared.mangaDex.viewMoc

    case .manganelo:
      return PersistenceController.shared.mangaNelo.viewMoc
    }
  }

  var searchDelegateType: SearchDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexSearchDelegate.self

    case .manganelo:
      return ManganeloSearchDelegate.self
    }
  }

  var detailsDelegateType: DetailsDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexDetailsDelegate.self

    case .manganelo:
      return ManganeloDetailsDelegate.self
    }
  }

  var chaptersDelegateType: ChaptersDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexChaptersDelegate.self

    case .manganelo:
      return ManganeloChaptersDelegate.self
    }
  }

  var pagesDelegateType: PagesDelegateType.Type {
    switch self {
    case .mangadex:
      return MangadexPagesDelegate.self

    case .manganelo:
      return ManganeloPagesDelegate.self
    }
  }

}