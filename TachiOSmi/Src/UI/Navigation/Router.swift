//
//  Router.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import Foundation
import SwiftUI

final class Router: ObservableObject {

  @Published var navPath = NavigationPath()

  func navigate(using navigator: some Navigator) {
    navPath.append(navigator)
  }

  func navigateBack() {
    navPath.removeLast()
  }

  func navigateToRoot() {
    navPath.removeLast(navPath.count)
  }

  func navigateToRootAndThen(to navigator: some Navigator) {
    navigateToRoot()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.navigate(using: navigator)
    }
  }

}
