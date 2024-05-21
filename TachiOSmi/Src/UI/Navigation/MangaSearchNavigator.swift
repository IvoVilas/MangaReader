//
//  MangaSearchNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation
import CoreData

struct MangaSearchNavigator: Navigator {

  let source: Source

  static func navigate(
    to entity: MangaSearchNavigator
  ) -> MangaSearchView {
    return MangaSearchView(
      source: entity.source
    )
  }

}
