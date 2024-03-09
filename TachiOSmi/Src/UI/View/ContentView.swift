//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import SwiftUI

struct ContentView: View {

  let viewModel: MangaLibraryViewModel

  var body: some View {
    NavigationStack {
      TabView {
        libraryView()
          .tabItem {
            Label(
              title: { Text("Library") },
              icon: { Image(systemName: "book.closed.fill") }
            )
          }

        searchView()
          .tabItem {
            Label(
              title: { Text("Search") },
              icon: { Image(systemName: "safari") }
            )
          }
      }
      .onAppear { viewModel.refreshLibrary() }
      .background(.white)
      .navigationDestination(for: Source.self) { source in
        MangaSearchView(
          viewModel: MangaSearchViewModel(
            source: source,
            datasource: SearchDatasource(
              delegate: source.searchDelegateType.init(
                httpClient: AppEnv.env.httpClient
              ),
              mangaCrud: AppEnv.env.mangaCrud,
              coverCrud: AppEnv.env.coverCrud,
              viewMoc: source.viewMoc
            )
          )
        )
      }
      .navigationDestination(for: MangaLibraryViewModel.MangaWrapper.self) { wrapper in
        MangaDetailsView(
          viewModel: MangaDetailsViewModel(
            source: wrapper.source,
            manga: MangaSearchResult(
              id: wrapper.manga.id,
              title: wrapper.manga.title,
              cover: wrapper.manga.cover,
              isSaved: wrapper.manga.isSaved
            ),
            mangaCrud: AppEnv.env.mangaCrud,
            chapterCrud: AppEnv.env.chapterCrud,
            coverCrud: AppEnv.env.coverCrud,
            authorCrud: AppEnv.env.authorCrud,
            tagCrud: AppEnv.env.tagCrud,
            httpClient: AppEnv.env.httpClient,
            systemDateTime: AppEnv.env.systemDateTime,
            viewMoc: wrapper.source.viewMoc
          )
        )
      }
    }
  }

  @ViewBuilder
  private func libraryView() -> some View {
    let columns = Array(
      repeating: GridItem(.flexible(), spacing: 16),
      count: 3
    )

    ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(viewModel.mangas) { result in
          NavigationLink(value: result) {
            makeMangaView(result.manga)
          }
        }
      }
      .padding(16)
    }
    .scrollIndicators(.hidden)
    .refreshable { viewModel.refreshLibrary() }
  }

  @ViewBuilder
  private func searchView() -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        ForEach(viewModel.sources) { source in
          NavigationLink(value: source) {
            makeSourceView(source)
              .padding(.horizontal, 24)
          }
        }
      }
      .padding(.top, 24)
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

  @ViewBuilder
  private func makeMangaView(
    _ manga: MangaModel
  ) -> some View {
    Image(uiImage: manga.cover.toUIImage() ?? UIImage())
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

          Text(manga.title)
            .font(.bold(.footnote)())
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
  ContentView(
    viewModel: MangaLibraryViewModel(
      mangaCrud: MangaCrud(),
      coverCrud: CoverCrud()
    )
  )
}
