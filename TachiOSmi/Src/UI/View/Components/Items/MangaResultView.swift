//
//  MangaResultView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import SwiftUI
import UIKit

struct MangaResultView: View {
  
  let title: String
  let cover: Data?
  let foregroundColor: Color
  var coverOpacity: CGFloat = 1

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Image(uiImage: cover.toUIImage() ?? UIImage())
        .resizable()
        .aspectRatio(0.625, contentMode: .fill)
        .background(.gray)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(coverOpacity)
      
      Text(title)
        // .font(.caption2)
        .font(.footnote)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .foregroundStyle(foregroundColor)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
  }
}

#Preview {
  ScrollView {
    MangaResultView(
      title: "Jujutsu Kaisen",
      cover: UIImage.jujutsuCover.pngData(),
      foregroundColor: .black
    ).frame(width: 150)
  }
}
