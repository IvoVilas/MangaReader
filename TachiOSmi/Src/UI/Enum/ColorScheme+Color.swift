//
//  ColorScheme+Color.swift
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

  var terciaryColor: Color {
    switch self {
    case .light:
      return Color(red: 205, green: 230, blue: 254)

    case .dark:
      return Color(red: 81, green: 149, blue: 213)
      
    @unknown default:
      fatalError()
    }

  }

}
