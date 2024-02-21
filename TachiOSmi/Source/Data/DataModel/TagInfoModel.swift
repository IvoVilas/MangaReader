//
//  TagInfoModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

struct TagModel: Identifiable, Hashable {

  let id: String
  let title: String

  static func from(_ tag: TagMO) -> TagModel {
    return TagModel(
      id: tag.id,
      title: tag.title
    )
  }

}
