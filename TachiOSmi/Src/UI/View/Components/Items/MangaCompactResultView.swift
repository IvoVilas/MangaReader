//
//  MangaCompactResultView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import SwiftUI

struct MangaCompactResultView: View {

  let title: String
  let cover: Data?
  let foregroundColor: Color
  var coverOpacity: CGFloat = 1

  var body: some View {
    Image(uiImage: cover.toUIImage() ?? UIImage())
      .resizable()
      .aspectRatio(0.625, contentMode: .fill)
      .background(.gray)
      .opacity(coverOpacity)
      .overlay {
        ZStack(alignment: .bottomLeading) {
          LinearGradient(
            gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
            startPoint: .center,
            endPoint: .bottom
          )

          Text(title)
            .font(.footnote.bold())
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}

#Preview {
  ScrollView {
    MangaCompactResultView(
      title: "Jujutsu Kaisen",
      cover: UIImage.jujutsuCover.pngData(),
      foregroundColor: .black
    ).frame(width: 150)
  }
}
