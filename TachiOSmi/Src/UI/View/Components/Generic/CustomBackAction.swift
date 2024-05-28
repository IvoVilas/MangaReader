//
//  CustomBackAction.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 04/03/2024.
//

import SwiftUI

struct CustomBackAction: View {

  @Environment(\.router) private var router

  let tintColor: Color

  init(
    tintColor: Color = .gray
  ) {
    self.tintColor = tintColor
  }

  var body: some View {
    Button {
      router.navigateBack()
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
