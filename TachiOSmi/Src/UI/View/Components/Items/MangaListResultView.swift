//
//  MangaListResultView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import SwiftUI

struct MangaListResultView<Content: View>: View {

  let title: String
  let cover: Data?
  let foregroundColor: Color
  var opacity: CGFloat = 1
  var trailingContent: () -> Content

  var body: some View {
    HStack {
      Image(uiImage: cover.toUIImage() ?? .coverNotFound)
        .resizable()
        .scaledToFill()
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .opacity(opacity)

      Spacer().frame(width: 8)

      Text(title)
        .font(.subheadline)
        .lineLimit(1)
        .foregroundStyle(foregroundColor)

      Spacer()

      trailingContent()
        .frame(minWidth: 16)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  ScrollView {
    MangaListResultView(
      title: "Jujutsu Kaisen",
      cover: UIImage.jujutsuCover.pngData(),
      foregroundColor: .black,
      trailingContent: {
        Text("123")
          .font(.footnote)
          .lineLimit(1)
          .foregroundStyle(.white)
          .padding(4)
          .background(.blue)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
    )
    .padding(.horizontal, 24)
  }
}
