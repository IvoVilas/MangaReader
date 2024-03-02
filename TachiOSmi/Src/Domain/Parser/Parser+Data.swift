//
//  Parser+Data.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

struct MangaParsedData {

  let id: String
  let title: String
  let description: String?
  let status: MangaStatus
  let tags: [TagModel]
  let authors: [AuthorModel]
  let coverInfo: String

  func convertToModel(cover: Data? = nil) -> MangaModel {
    return MangaModel(
      id: id,
      title: title,
      description: description,
      status: status,
      cover: cover,
      tags: tags.sorted { $0.title < $1.title },
      authors: authors
    )
  }

}
