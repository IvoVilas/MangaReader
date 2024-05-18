//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import SwiftUI

struct ContentView: View {

  enum Tabs: String {
    case library
    case updates
    case search
    case options
  }

  @Environment(\.managedObjectContext) private var viewMoc
  @Environment(\.colorScheme) private var scheme

  @State private var selectedTab: Tabs = .library

  let sourcesViewModel: MangaSourcesViewModel
  let refreshLibraryUseCase: RefreshLibraryUseCase

  var body: some View {
    NavigationStack {
      TabView(selection: $selectedTab) {
        MangaLibraryView(viewMoc: viewMoc)
          .padding(top: 24, leading: 24, trailing: 24)
          .tabItem {
            Label(
              title: { Text("Library") },
              icon: { Image(systemName: "book.closed.fill") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
          .tag(Tabs.library)

        MangaUpdatesView(
          refreshLibraryUseCase: refreshLibraryUseCase,
          viewMoc: viewMoc
        )
        .padding(top: 24, leading: 24, trailing: 24)
        .tabItem {
          Label(
            title: { Text("Updates") },
            icon: { Image(systemName: "clock.arrow.2.circlepath") }
          )
        }
        .toolbarBackground(.visible, for: .tabBar)
        .tag(Tabs.updates)

        MangaSourcesView(viewModel: sourcesViewModel)
          .padding(top: 24, leading: 24, trailing: 24)
          .tabItem {
            Label(
              title: { Text("Search") },
              icon: { Image(systemName: "safari") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
          .tag(Tabs.search)

        AppOptionsView()
          .padding(top: 24, leading: 24, trailing: 24)
          .tabItem {
            Label(
              title: { Text("More") },
              icon: { Image(systemName: "ellipsis") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
          .tag(Tabs.options)
      }
      .navigationTitle(selectedTab.rawValue.capitalized)
      .toolbar(.hidden, for: .navigationBar)
      .registerNavigator(MangaDetailsNavigator.self)
      .registerNavigator(MangaReaderNavigator.self)
      .registerNavigator(MangaSearchNavigator.self)
    }
  }

}

#Preview {
  ContentView(
    sourcesViewModel: MangaSourcesViewModel(),
    refreshLibraryUseCase: RefreshLibraryUseCase(
      mangaCrud: MangaCrud(),
      chapterCrud: ChapterCrud(),
      httpClient: HttpClient(),
      systemDateTime: SystemDateTime(),
      moc: PersistenceController.preview.container.newBackgroundContext()
    )
  )
}
