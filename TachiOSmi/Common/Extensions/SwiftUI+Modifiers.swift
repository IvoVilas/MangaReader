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

extension Color {

  init(
    red: CGFloat,
    green: CGFloat,
    blue: CGFloat,
    alpha: CGFloat = 1
  ) {
    if red <= 1, green <= 1, blue <= 1 {
      self.init(
        uiColor: UIColor(
          red: max(0, red),
          green: max(0, green),
          blue: max(0, blue),
          alpha: alpha
        )
      )
    } else {
      self.init(
        uiColor: UIColor(
          red: min(1, max(0, red / 256)),
          green: min(1, max(0, green / 256)),
          blue: min(1, max(0, blue / 256)),
          alpha: alpha
        )
      )
    }
  }

}
