//
//  ToastInfo.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 29/10/2024.
//

import Foundation

enum ToastInfo {

  case error(message: String)
  case warning(message: String)
  case success(message: String)
  case info(message: String)

  var message: String {
    switch self {
    case let .error(message), let .warning(message), let .success(message), let .info(message):
      return message
    }
  }

  var style: ToastStyle {
    switch self {
    case .error:
      return .error

    case .warning:
      return .warning

    case .success:
      return .success

    case .info:
      return .info
    }
  }

}
