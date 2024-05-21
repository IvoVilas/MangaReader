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

  static func navigate(
    to entity: MangaDetailsNavigator
  ) -> MangaDetailsView {
    return MangaDetailsView(
      source: entity.source,
      manga: entity.manga
    )
  }

  static func fromSearchResult(
    _ result: MangaSearchResult,
    source: Source
  ) -> MangaDetailsNavigator {
    return MangaDetailsNavigator(
      source: source,
      manga: result
    )
  }

  static func fromMangaWrapper(
    _ wrapper: MangaLibraryProvider.MangaWrapper
  ) -> MangaDetailsNavigator {
    return MangaDetailsNavigator(
      source: wrapper.source,
      manga: wrapper.manga
    )
  }

}
