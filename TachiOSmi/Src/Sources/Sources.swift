//
//  Sources.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

enum Source {

  case mangaDex
  case mangaNelo

  var id: String {
    switch self {
    case .mangaDex:
      "0"

    case .mangaNelo:
      "1"
    }
  }

}
