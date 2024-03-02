//
//  MangaSources.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

protocol SourceType {

  associatedtype SearchDelegate: SearchDelegateType
  associatedtype DetailsDelegate: DetailsDelegateType
  associatedtype ChaptersDelegate: ChaptersDelegateType
  associatedtype PagesDelegate: PagesDelegateType

  static var database: MangaDatabaseType { get }
  static var name: String { get }

}

final class MangadexMangaSource: SourceType {

  typealias SearchDelegate = MangadexSearchDelegate
  typealias DetailsDelegate = MangadexDetailsDelegate
  typealias ChaptersDelegate = MangadexChaptersDelegate
  typealias PagesDelegate = MangadexPagesDelegate

  static let database: MangaDatabaseType = PersistenceController.shared.mangaDex
  static let name = "MangaDex"

}

final class ManganeloMangaSource: SourceType {

  typealias SearchDelegate = ManganeloSearchDelegate
  typealias DetailsDelegate = ManganeloDetailsDelegate
  typealias ChaptersDelegate = ManganeloChaptersDelegate
  typealias PagesDelegate = ManganeloPagesDelegate

  static let database: MangaDatabaseType = PersistenceController.shared.mangaNelo
  static let name = "MangaNelo"

}
