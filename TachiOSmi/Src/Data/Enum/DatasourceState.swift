//
//  DatasourceState.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 19/02/2024.
//

import Foundation

enum DatasourceState {
  
  case starting
  case loading
  case normal

  var isLoading: Bool {
    switch self {
    case .loading, .starting:
      return true

    default:
      return false
    }
  }

}
