//
//  MangaDetailsNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation
import CoreData

struct MangaDetailsNavigator: Navigator {

  let manga: MangaSearchResult

  static func navigate(
    to entity: MangaDetailsNavigator
  ) -> MangaDetailsView {
    return MangaDetailsView(
      manga: entity.manga
    )
  }

}
