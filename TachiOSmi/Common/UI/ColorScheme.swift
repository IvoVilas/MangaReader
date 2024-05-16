//
//  ColorScheme.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import SwiftUI

extension ColorScheme {

  var backgroundColor: Color {
    switch self {
    case .light:
      return .white
    case .dark:
      return .black
    @unknown default:
      fatalError()
    }
  }

  var foregroundColor: Color {
    switch self {
    case .light:
      return .black
    case .dark:
      return .white
    @unknown default:
      fatalError()
    }
  }

  var secondaryColor: Color {
    return .gray
  }

}
