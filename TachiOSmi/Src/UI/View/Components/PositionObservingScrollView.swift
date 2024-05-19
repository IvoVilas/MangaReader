//
//  PositionObservingScrollView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 19/05/2024.
//

import Foundation
import SwiftUI

struct PositionObservingScrollView<Content: View>: View {

  @Binding var offset: CGPoint
  @ViewBuilder var content: () -> Content

  private let coordinateSpaceName = UUID()

  var body: some View {
    ScrollView {
      PositionObservingView(
        coordinateSpace: .named(coordinateSpaceName),
        position: $offset
      ) {
        content()
      }
    }
    .coordinateSpace(name: coordinateSpaceName)
  }

}

private struct Preview_Content: View {

  @State private var offset = CGPoint.zero

  var body: some View {
    VStack {
      Text("Offset: \(offset.y)")

      PositionObservingScrollView(offset: $offset) {
        Text("Hello World")
      }
    }
  }
}


#Preview {
  Preview_Content()
}
