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
          .toolbarBackground(.visible, for: .tabBar)

        Text("TODO")
          .tabItem {
            Label(
              title: { Text("Updates") },
              icon: { Image(systemName: "clock.arrow.2.circlepath") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)

        MangaSourcesView(viewModel: sourcesViewModel)
          .padding(24)
          .tabItem {
            Label(
              title: { Text("Search") },
              icon: { Image(systemName: "safari") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)

        Text("TODO")
          .tabItem {
            Label(
              title: { Text("More") },
              icon: { Image(systemName: "ellipsis") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
      }
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
      viewMoc: PersistenceController.preview.container.viewContext
    ),
    sourcesViewModel: MangaSourcesViewModel()
  )
}

extension ColorScheme {

  var backgroundColor: Color {
    switch self {
    case .light:
      return .white
    case .dark:
      return .black
    @unknown default:
      fatalError()
    }
  }

  var foregroundColor: Color {
    switch self {
    case .light:
      return .black
    case .dark:
      return .white
    @unknown default:
      fatalError()
    }
  }

  var secondaryColor: Color {
    return .gray
  }

}
