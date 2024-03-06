//
//  PageDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation

enum PageModel: Identifiable {
  
  case remote(String, Int, Data)
  case loading(String, Int)
  case notFound(String, Int)

  var id: String { return url }

  var url: String {
    switch self {
    case .remote(let url, _, _):
      return url

    case .loading(let url, _):
      return url

    case .notFound(let url, _):
      return url
    }
  }

  var position: Int {
    switch self {
    case .remote(_, let pos, _):
      return pos

    case .loading(_, let pos):
      return pos

    case .notFound(_, let pos):
      return pos
    }
  }

}
