//
//  MangaDetailsNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation

struct MangaDetailsNavigator: Navigator {

  let manga: MangaSearchResult

  init(manga: MangaSearchResult) {
    self.manga = manga
  }

  init(
    id: String,
    sourceId: String
  ) {
    manga = MangaSearchResult(
      id: id,
      title: "",
      cover: nil, 
      source: Source.safeInit(from: sourceId)
    )
  }

  static func navigate(
    to entity: MangaDetailsNavigator
  ) -> MangaDetailsView {
    return MangaDetailsView(
      manga: entity.manga
    )
  }

}
