//
//  MangaSourcesView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import SwiftUI

struct MangaSourcesView: View {

  let viewModel: MangaSourcesViewModel

  var body: some View {
    VStack(alignment: .leading) {
      Text("Sources")
        .font(.title)

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          ForEach(viewModel.sources) { source in
            NavigationLink(value: source) {
              makeSourceView(source)
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func makeSourceView(
    _ source: Source
  ) -> some View {
    HStack(spacing: 16) {
      Image(uiImage: source.logo)
        .resizable()
        .scaledToFit()
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 8))

      Text(source.name)
        .font(.title2)
        .tint(.gray)

      Spacer()

      Image(systemName: "chevron.right")
        .tint(.gray)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.white)
        .stroke(.gray, lineWidth: 1)
    )
  }

}

#Preview {
  MangaSourcesView(
    viewModel: MangaSourcesViewModel(inMemory: true)
  )
}
