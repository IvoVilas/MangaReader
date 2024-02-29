//
//  Parser+Error.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 25/02/2024.
//

import Foundation

enum ParserError: Error {
  case parsingError
  case parameterNotFound(String)

  var localizedDescription: String {
    switch self {
    case .parsingError:
        return "Error while parsing response"

    case .parameterNotFound(let parameter):
      return "The parameter \(parameter) not found"
    }
  }
}
