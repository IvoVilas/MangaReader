//
//  IconSource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 18/05/2024.
//

import Foundation
import SwiftUI

enum IconSource {

  case asset(ImageResource)
  case system(String)

  func image() -> Image {
    switch self {
    case .asset(let imageResource):
      return Image(imageResource)

    case .system(let name):
      return Image(systemName: name)
    }
  }

}
