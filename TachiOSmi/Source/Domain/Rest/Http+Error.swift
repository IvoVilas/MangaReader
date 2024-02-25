//
//  Http+Error.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 25/02/2024.
//

import Foundation

enum HttpError: Error {
  case invalidUrl
  case invalidResponse
  case responseNotOk
  case requestError(Error)

  var localizedDescription: String {
    switch self {
    case .invalidUrl:
      return "Invalid url"

    case .invalidResponse:
      return "Could not parse response"

    case .responseNotOk:
      return "Response code is not 200"

    case .requestError(let error):
      return "Request error: \(error.localizedDescription)"
    }
  }
}
