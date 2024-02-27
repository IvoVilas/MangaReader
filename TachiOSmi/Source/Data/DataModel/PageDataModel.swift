//
//  PageDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation

enum PageModel: Identifiable {
  case remote(Int, Data)
  case loading(Int)
  case notFound(Int)

  var id: String {
    switch self {
    case .remote(let pos, _):
      return "\(pos)"

    case .loading(let pos):
      return "\(pos)"

    case .notFound(let pos):
      return "\(pos)"
    }
  }
}
