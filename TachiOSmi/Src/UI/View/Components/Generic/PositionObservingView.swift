//
//  PositionObservingView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 19/05/2024.
//

import Foundation
import SwiftUI

struct PositionObservingView<Content: View>: View {

  struct PreferenceKey: SwiftUI.PreferenceKey {
    static var defaultValue: CGPoint { .zero }

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
  }

  var coordinateSpace: CoordinateSpace
  @Binding var position: CGPoint
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .background(
        GeometryReader { geometry in
          SwiftUI.Color.clear.preference(
            key: PreferenceKey.self,
            value: geometry.frame(in: coordinateSpace).origin
          )
        }
      )
      .onPreferenceChange(PreferenceKey.self) { position in
        self.position = position

        /*
         // Limit usage but greatly increase performance
        if position.y >= 0 && abs(position.y - self.position.y) >= 1 {
          self.position = position
        }
         */
      }
  }

}

private struct Preview_Content: View {

  @State private var position = CGPoint.zero

  private let coordinateSpaceName = UUID()

  var body: some View {
    VStack {
      Text("Offset: \(position.y)")

      ScrollView {
        PositionObservingView(
          coordinateSpace: .named(coordinateSpaceName),
          position: $position
        ) {
          Text("Hello world")
        }
      }
      .coordinateSpace(name: coordinateSpaceName)
    }
  }
}

#Preview {
  Preview_Content()
}
