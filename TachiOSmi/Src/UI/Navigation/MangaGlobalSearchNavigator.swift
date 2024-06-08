//
//  MangaGlobalSearchNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 08/06/2024.
//

import Foundation

struct MangaGlobalSearchNavigator: Navigator {

  static func navigate(
    to entity: MangaGlobalSearchNavigator
  ) -> MangaGlobalSearchView {
    return MangaGlobalSearchView()
  }

}
