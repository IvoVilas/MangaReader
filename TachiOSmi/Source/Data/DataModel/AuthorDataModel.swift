//
//  AuthorDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation

struct AuthorModel: Identifiable, Hashable {

  let id: String
  let name: String

  static func from(_ author: AuthorMO) -> AuthorModel {
    return AuthorModel(
      id: author.id,
      name: author.name
    )
  }

}
