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

}
