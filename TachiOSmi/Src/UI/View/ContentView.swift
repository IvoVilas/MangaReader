//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import SwiftUI


struct ContentView: View {

  var body: some View {
    MangaSearchView(
      viewModel: MangaSearchViewModel(
        datasource: SearchDatasource(
          delegate: ManganeloSearchDelegate(
            httpClient: AppEnv.env.httpClient
          ),
          mangaCrud: AppEnv.env.mangaCrud,
          coverCrud: AppEnv.env.coverCrud
        )
      )
    )
  }

}

#Preview {
  ContentView()
}
