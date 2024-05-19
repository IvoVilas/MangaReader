//
//  Result.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 19/05/2024.
//

import Foundation

enum Result<ResultType, ErrorType> {

  case success(ResultType)
  case failure(ErrorType)

}
