//
//  Result.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 19/05/2024.
//

import Foundation

enum EmptyResult<ErrorType> {

  case success
  case failure(ErrorType)

  var isSuccess: Bool {
    switch self {
    case .success:
      return true

    case .failure:
      return false
    }
  }

}

enum Result<ResultType, ErrorType> {

  case success(ResultType)
  case failure(ErrorType)

  var isSuccess: Bool {
    switch self {
    case .success:
      return true

    case .failure:
      return false
    }
  }

}
