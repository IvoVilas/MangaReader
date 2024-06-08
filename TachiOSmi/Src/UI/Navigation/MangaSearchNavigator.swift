//
//  MangaSearchNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation

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

struct MangaLoadedSearchNavigator: Navigator {

  let input: String
  let datasource: SearchDatasource

  static func navigate(
    to entity: MangaLoadedSearchNavigator
  ) -> MangaSearchView {
    return MangaSearchView(
      input: entity.input,
      datasource: entity.datasource
    )
  }

}

extension SearchDatasource: Hashable {

  static func == (lhs: SearchDatasource, rhs: SearchDatasource) -> Bool {
      ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }

  func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(self))
  }

}
