//
//  MangaFavoritesView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 24/10/2024.
//

import SwiftUI

struct MangaFavoritesView: View {

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var scheme

  @StateObject var viewModel: MangaFavoritesViewModel

  init() {
    _viewModel = StateObject(
      wrappedValue: MangaFavoritesViewModel()
    )
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Favorites")
        .foregroundStyle(scheme.foregroundColor)
        .font(.title)

      ZStack {
        VStack(spacing: 8) {
          Image(systemName: "heart.text.square")
            .resizable()
            .scaledToFit()
            .foregroundStyle(scheme.secondaryColor)
            .frame(height: 150)

          Text("You have no favorites")
            .foregroundStyle(scheme.secondaryColor)
            .font(.title3)
        }
        .opacity(viewModel.mangas.isEmpty ? 1 : 0)

        ScrollView {
          resultCollectionView()
        }
        .scrollIndicators(.hidden)
        .opacity(viewModel.mangas.isEmpty ? 0 : 1)
      }
    }
  }

}

// MARK: Collection
private extension MangaFavoritesView {

  @ViewBuilder
  private func resultCollectionView() -> some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
      spacing: 16
    ) {
      ForEach(viewModel.mangas) { result in
        Button { 
          router.navigate(using: MangaFavoritePagesNavigator(mangaPages: result))
        } label: {
          MangaResultItemView(
            id: result.manga.id,
            cover: result.manga.cover,
            title: result.manga.title,
            textColor: scheme.foregroundColor
          )
          .equatable()
        }
      }
    }
  }

}

// MARK: Item
private struct MangaResultItemView: View, Equatable {

  let id: String
  let cover: Data?
  let title: String
  let textColor: Color

  static func == (lhs: MangaResultItemView, rhs: MangaResultItemView) -> Bool {
    guard
      lhs.id == rhs.id,
      lhs.textColor == rhs.textColor
    else {
      return false
    }

    return true
  }

  var body: some View {
    MangaCompactResultView(
      title: title,
      cover: cover,
      foregroundColor: textColor
    )
  }

}

#Preview {
  MangaFavoritesView()
}
