//
//  Sources.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

enum Source {

  case mangaDex

  var pagesDelegate: any PagesDelegateType.Type {
    switch self {
    case .mangaDex:
      return MangadexPagesDelegate.self
    }
  }

}
