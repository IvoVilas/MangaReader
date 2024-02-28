//
//  Datasource+Error.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 25/02/2024.
//

import Foundation

enum DatasourceError: Error {
  case errorParsingResponse(String)
  case networkError(String)
  case databaseError(String)
  case unexpectedError(String)
  case otherError(String)

  var localizedDescription: String {
    switch self {
    case .errorParsingResponse(let error):
      return "Error while parsing the request response\n\(error)"

    case .networkError(let error):
      return "Error during network request\n\(error)"

    case .databaseError(let error):
      return "Error during database operations\n\(error)"

    case .unexpectedError(let error):
      return "Unexpected error\n\(error)"

    case .otherError(let error):
      return error
    }
  }
}
