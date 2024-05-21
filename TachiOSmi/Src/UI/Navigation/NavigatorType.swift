//
//  NavigatorType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation
import SwiftUI

protocol Navigator: Hashable {

  associatedtype Destination: View

  static func navigate(to: Self) -> Destination

}

struct RegisterNavigator<NavigatorType: Navigator>: ViewModifier {

  func body(content: Content) -> some View {
    content
      .navigationDestination(for: NavigatorType.self) { entity in
        NavigatorType.navigate(to: entity)
      }
  }
}

extension View {
  
  func registerNavigator<NavigatorType: Navigator>(
    _ navigatorType: NavigatorType.Type
  ) -> some View {
    self.modifier(RegisterNavigator<NavigatorType>())
  }

}
