//
//  MangaDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 19/02/2024.
//

import Foundation
import UIKit

struct MangaModel: Identifiable, Hashable {

  let id: String
  let title: String
  let description: String?
  let status: MangaStatus
  var cover: UIImage?
  let tags: [TagModel]

  static func from(_ manga: MangaMO) -> MangaModel {
    var cover: UIImage?

    if let coverData = manga.coverArt {
      cover = UIImage(data: coverData)
    }

    return MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.about,
      status: .safeInit(from: manga.statusId),
      cover: cover,
      tags: manga.tags.map { .from($0) }
    )
  }

  static func from(_ manga: MangaMO, coverData: Data?) -> MangaModel {
    var cover: UIImage?

    if let coverData {
      cover = UIImage(data: coverData)
    }

    return MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.about,
      status: .safeInit(from: manga.statusId),
      cover: cover,
      tags: manga.tags.map { .from($0) }
    )
  }

}
