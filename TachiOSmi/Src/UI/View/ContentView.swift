//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import SwiftUI


struct ContentView: View {

  private var sources = [
    Source.mangadex,
    Source.manganelo
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          ForEach(Array(sources.enumerated()), id:\.element.id) { _, source in
            NavigationLink(value: source) {
              makeSourceView(source)
                .padding(.horizontal, 24)
            }
          }
        }
        .padding(.top, 24)
      }
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

}

#Preview {
  ContentView()
}
