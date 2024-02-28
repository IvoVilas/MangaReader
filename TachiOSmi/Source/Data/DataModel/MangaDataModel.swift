//
//  MangaDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 19/02/2024.
//

import Foundation

struct MangaModel: Identifiable, Hashable {

  let id: String
  let title: String
  let description: String?
  let status: MangaStatus
  var cover: Data?
  let tags: [TagModel]
  let authors: [AuthorModel]

  static func from(_ manga: MangaMO) -> MangaModel {
    return MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.synopsis,
      status: .safeInit(from: manga.statusId),
      cover: nil,
      tags: manga.tags.map { .from($0) }.sorted { $0.title < $1.title },
      authors: manga.authors.map { .from($0) }
    )
  }

  static func from(
    _ manga: MangaMO,
    cover: Data
  ) -> MangaModel {
    return MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.synopsis,
      status: .safeInit(from: manga.statusId),
      cover: cover,
      tags: manga.tags.map { .from($0) }.sorted { $0.title < $1.title },
      authors: manga.authors.map { .from($0) }
    )
  }

}
