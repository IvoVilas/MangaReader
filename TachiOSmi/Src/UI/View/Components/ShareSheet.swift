//
//  ShareSheet.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 19/05/2024.
//

import Foundation
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {

  let activityItems: [Any]
  let completion: (() -> Void)?

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )

    controller.completionWithItemsHandler = { _, _, _, _ in
      completion?()
    }

    return controller
  }

  func updateUIViewController(
    _ uiViewController: UIActivityViewController,
    context: Context
  ) {

  }
}

private struct Preview_Content: View {

  @State var presenting = false

  var body: some View {
    VStack {
      Button {
        presenting.toggle()
      } label: {
        Text("Share text")
      }
    }
    .sheet(isPresented: $presenting) {
      ShareSheet(activityItems: ["This is a message"], completion: nil)
        .presentationDetents([.medium, .large])
    }
  }

}

// TODO: Implement preview
#Preview {
  Preview_Content()
}
