//
//  MangaFavoritePagesView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/10/2024.
//

import SwiftUI

struct MangaFavoritePagesView: View {

  @Environment(\.colorScheme) private var scheme

  @StateObject var viewModel: MangaFavoritePagesViewModel

  init(
    mangaPages: MangaFavoritePages
  ) {
    _viewModel = StateObject(
      wrappedValue: MangaFavoritePagesViewModel(
        mangaPages: mangaPages
      )
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      navbarView()

      ZStack(alignment: .top) {
        ScrollView {
          Spacer().frame(height: 16)

          VStack(spacing: 16) {
            pageView(viewModel.spotlightPage?.data)

            LazyVGrid(
              columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
              spacing: 16
            ) {
              ForEach(viewModel.pages) { page in
                pageView(page.data)
              }
            }
          }
        }
        .scrollIndicators(.hidden)

        LinearGradient(
          gradient: Gradient(colors: [scheme.backgroundColor, .clear]),
          startPoint: .top,
          endPoint: .bottom
        ).frame(height: 8)
      }
    }
    .padding(.horizontal, 24)
    .navigationBarBackButtonHidden(true)
  }

  @ViewBuilder
  private func navbarView() -> some View {
    HStack(spacing: 16) {
      CustomBackAction(tintColor: scheme.foregroundColor)
        .frame(width: 20, height: 20)

      Text(viewModel.title)
        .foregroundStyle(scheme.foregroundColor)
        .font(.title)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

}

extension MangaFavoritePagesView {

  @ViewBuilder
  private func pageView(_ pageData: Data?) -> some View {
    if let pageData, let uiImage = UIImage(data: pageData) {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .background(.gray)
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(scheme.foregroundColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    } else {
      Text("Unable to load image")
        .foregroundColor(.red)
    }
  }

}

#Preview {
  MangaFavoritePagesView(
    mangaPages: MangaFavoritePages(
      manga: MangaModel(
        id: "1",
        title: "Jujutsu Kaisen",
        description: nil,
        isSaved: true,
        source: .unknown,
        status: .ongoing,
        readingDirection: .leftToRight,
        cover: UIImage.jujutsuCover.jpegData(compressionQuality: 1),
        tags: [],
        authors: []
      ),
      pages: [
        StoredPageModel(
          id: "1",
          mangaId: "1",
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuCover.jpegData(compressionQuality: 1)
        ),
        StoredPageModel(
          id: "2",
          mangaId: "1",
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuCover.jpegData(compressionQuality: 1)
        ),
        StoredPageModel(
          id: "3",
          mangaId: "1",
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuCover.jpegData(compressionQuality: 1)
        ),
        StoredPageModel(
          id: "4",
          mangaId: "1",
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuCover.jpegData(compressionQuality: 1)
        )
      ]
    )
  )
}
