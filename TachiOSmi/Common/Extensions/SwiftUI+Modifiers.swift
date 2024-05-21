//
//  SwiftUI+Modifiers.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 05/03/2024.
//

import Foundation
import SwiftUI

extension View {

  @ViewBuilder func `if`<Content: View>(
    _ condition: Bool,
    transform: (Self) -> Content
  ) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }

  @inlinable func padding(
    top: CGFloat = 0,
    leading: CGFloat = 0,
    bottom: CGFloat = 0,
    trailing: CGFloat = 0
  ) -> some View {
    return self.padding(
      EdgeInsets(
        top: top,
        leading: leading,
        bottom: bottom,
        trailing: trailing
      )
    )
  }

}
