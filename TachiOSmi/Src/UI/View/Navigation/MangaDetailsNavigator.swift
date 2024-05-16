//
//  MangaDetailsNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation
import CoreData

struct MangaDetailsNavigator: Navigator {

  let source: Source
  let manga: MangaSearchResult
  let viewMoc: NSManagedObjectContext
  let moc: NSManagedObjectContext

  static func navigate(
    to entity: MangaDetailsNavigator
  ) -> MangaDetailsView {
    return MangaDetailsView(
      source: entity.source,
      manga: entity.manga,
      viewMoc: entity.viewMoc,
      moc: entity.moc
    )
  }

  static func fromSearchResult(
    _ result: MangaSearchResult,
    source: Source,
    viewMoc: NSManagedObjectContext,
    moc: NSManagedObjectContext
  ) -> MangaDetailsNavigator {
    return MangaDetailsNavigator(
      source: source,
      manga: result,
      viewMoc: viewMoc,
      moc: moc
    )
  }

}
