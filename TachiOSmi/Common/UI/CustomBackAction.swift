//
//  CustomBackAction.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 04/03/2024.
//

import SwiftUI

struct CustomBackAction: View {

  @Environment(\.dismiss) private var dismiss

  let tintColor: Color

  init(
    tintColor: Color = .gray
  ) {
    self.tintColor = tintColor
  }

  var body: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "arrow.left")
        .font(.headline)
        .tint(tintColor)
    }
  }
}

#Preview {
    CustomBackAction()
}
