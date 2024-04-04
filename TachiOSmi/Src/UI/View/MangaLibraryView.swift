//
//  MangaLibraryView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import SwiftUI

struct MangaLibraryView: View {

  let viewModel: MangaLibraryViewModel

  let columns = Array(
    repeating: GridItem(.flexible(), spacing: 16),
    count: 3
  )
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Library")
        .font(.title)

      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(viewModel.mangas) { result in
            NavigationLink(value: result) {
              makeMangaView(result)
            }
          }
        }
      }
      .scrollIndicators(.hidden)
      .onAppear { viewModel.refreshLibrary() }
      .refreshable { viewModel.refreshLibrary() }
    }
  }

  @ViewBuilder
  private func makeMangaView(
    _ manga: MangaLibraryViewModel.MangaWrapper
  ) -> some View {
    ZStack(alignment: .topLeading) {
      Image(uiImage: manga.manga.cover.toUIImage() ?? UIImage())
        .resizable()
        .aspectRatio(0.625, contentMode: .fill)
        .background(.gray)
        .overlay {
          ZStack(alignment: .bottomLeading) {
            LinearGradient(
              gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
              startPoint: .center,
              endPoint: .bottom
            )

            Text(manga.manga.title)
              .font(.footnote)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
              .foregroundStyle(.white)
              .padding(.horizontal, 4)
              .padding(.bottom, 8)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))

      Text("\(manga.unreadChapters)")
        .font(.footnote)
        .lineLimit(1)
        .foregroundStyle(.white)
        .padding(4)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.leading, 8)
        .padding(.top, 8)
        .opacity(manga.unreadChapters > 0 ? 1 : 0)
    }
  }

}

#Preview {
  MangaLibraryView(
    viewModel: MangaLibraryViewModel(
      mangaCrud: MangaCrud(),
      coverCrud: CoverCrud(),
      chapterCrud: ChapterCrud()
    )
  )
}
