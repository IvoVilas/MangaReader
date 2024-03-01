//
//  MangaSearchData.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

struct MangaSearchData: Identifiable, Hashable, Equatable {
  let id: String
  let title: String
  let cover: Data?
}
