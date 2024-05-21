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

}

enum Result<ResultType, ErrorType> {

  case success(ResultType)
  case failure(ErrorType)

}
