//
//  MangaFavoritePagesNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/10/2024.
//

import Foundation

struct MangaFavoritePagesNavigator: Navigator {

  let mangaPages: MangaFavoritePages

  static func navigate(
    to entity: MangaFavoritePagesNavigator
  ) -> MangaFavoritePagesView {
    return MangaFavoritePagesView(
      mangaPages: entity.mangaPages
    )
  }

}
