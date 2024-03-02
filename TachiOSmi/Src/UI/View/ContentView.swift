//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import SwiftUI


struct ContentView: View {

  var body: some View {
    TabView {
      MangaSearchView<MangadexMangaSource>(
        viewModel: MangaSearchViewModel(
          datasource: SearchDatasource(
            delegate: MangadexSearchDelegate(
              httpClient: AppEnv.env.httpClient,
              mangaParser: AppEnv.env.mangaParser
            ),
            mangaCrud: AppEnv.env.mangaCrud,
            coverCrud: AppEnv.env.coverCrud
          )
        )
      ).tabItem { Text("Mangadex") }

      MangaSearchView<ManganeloMangaSource>(
        viewModel: MangaSearchViewModel(
          datasource: SearchDatasource(
            delegate: ManganeloSearchDelegate(
              httpClient: AppEnv.env.httpClient,
              mangaParser: AppEnv.env.mangaParser
            ),
            mangaCrud: AppEnv.env.mangaCrud,
            coverCrud: AppEnv.env.coverCrud
          )
        )
      ).tabItem { Text("Manganelo") }
    }
  }

}

#Preview {
  ContentView()
}
