//
//  MangaSourcesView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import SwiftUI

struct MangaSourcesView: View {

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var scheme

  @StateObject var viewModel = MangaSourcesViewModel()

  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 0) {
        Text("Sources")
          .foregroundStyle(scheme.foregroundColor)
          .font(.title)

        Spacer()

        Button {
          router.navigate(using: MangaGlobalSearchNavigator())
        } label: {
          Image(.globalSearch)
            .scaledToFit()
            .foregroundStyle(scheme.foregroundColor)
        }
      }

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          ForEach(viewModel.sources) { source in
            Button {
              router.navigate(using: MangaSearchNavigator(source: source))
            } label: {
              makeSourceView(source)
            }
          }
        }
        .padding(1)
      }
    }
    .background(scheme.backgroundColor)
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
        .foregroundStyle(scheme.secondaryColor)
        .font(.title2)

      Spacer()

      Image(systemName: "chevron.right")
        .foregroundStyle(scheme.secondaryColor)
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(scheme.backgroundColor)
        .stroke(scheme.secondaryColor, lineWidth: 1)
    )
  }

}

#Preview {
  MangaSourcesView()
}
