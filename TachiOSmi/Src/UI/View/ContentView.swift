//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import SwiftUI

struct ContentView: View {

  let libraryViewModel: MangaLibraryViewModel
  let sourcesViewModel: MangaSourcesViewModel

  var body: some View {
    NavigationStack {
      TabView {
        MangaLibraryView(viewModel: libraryViewModel)
          .padding(24)
          .tabItem {
            Label(
              title: { Text("Library") },
              icon: { Image(systemName: "book.closed.fill") }
            )
          }

        MangaSourcesView(viewModel: sourcesViewModel)
          .padding(24)
          .tabItem {
            Label(
              title: { Text("Search") },
              icon: { Image(systemName: "safari") }
            )
          }
      }
      .background(.white)
      .navigationDestination(for: MangaLibraryViewModel.MangaWrapper.self) { wrapper in
        MangaDetailsView(
          viewModel: libraryViewModel.buildDetailsViewModel(for: wrapper)
        )
      }
      .navigationDestination(for: Source.self) { source in
        MangaSearchView(
          viewModel: sourcesViewModel.buildSearchViewModel(for: source)
        )
      }
    }
  }

}

#Preview {
  ContentView(
    libraryViewModel: MangaLibraryViewModel(
      mangaCrud: MangaCrud(),
      coverCrud: CoverCrud(),
      chapterCrud: ChapterCrud(),
      inMemory: true
    ),
    sourcesViewModel: MangaSourcesViewModel(
      inMemory: true
    )
  )
}
