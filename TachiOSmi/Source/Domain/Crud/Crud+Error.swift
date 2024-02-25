//
//  Crud+Error.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 25/02/2024.
//

import Foundation

enum CrudError: Error {
  case requestError(Error)
  case wrongRequestType
  case mangaNotFound(id: String)
  case saveError
  case failedEntityCreation

  var localizedDescription: String {
    switch self {
    case .requestError(let error):
      return "Database request failed: \(error.localizedDescription)"

    case .wrongRequestType:
      return "Request result type did not match data type"

    case .mangaNotFound(let id):
      return "Manga not found: \(id)"

    case .saveError:
      return "Could not save database changes"

    case .failedEntityCreation:
      return "Could not create dabase entity"
    }
  }
}
