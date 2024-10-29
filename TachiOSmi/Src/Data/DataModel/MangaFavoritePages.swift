//
//  MangaFavoritePages.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 29/10/2024.
//

import Foundation

struct MangaFavoritePages: Identifiable, Hashable {

  let manga: MangaModel
  let pages: [StoredPageModel]

  var id: String {
    manga.id
  }

}
