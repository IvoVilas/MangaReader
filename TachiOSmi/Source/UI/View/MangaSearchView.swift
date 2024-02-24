//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI
import CoreData

struct MangaSearchView: View {

  @ObservedObject var viewModel: MangaSearchViewModel

  @FocusState private var inputFieldIsFocused: Bool

  var body: some View {
    NavigationView {
      VStack() {
        Text("Manga Search")
          .font(.largeTitle)

        TextField(
          "Manga title",
          text: $viewModel.input
        )
        .keyboardType(.default)
        .focused($inputFieldIsFocused)
        .textInputAutocapitalization(.sentences)
        .autocorrectionDisabled(true)
        .padding(.leading, 16)

        Button {
          viewModel.doSearch()
        } label: {
          Text("Search")
            .font(.callout)
        }

        Spacer().frame(height: 50)

        Text("Results")
          .font(.title3)

        ZStack(alignment: .top) {
          ProgressView()
            .progressViewStyle(.circular)
            .opacity(viewModel.isLoading ? 1 : 0)

          ScrollView {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(viewModel.results) { manga in
                NavigationLink {
                  makeDetailsView(manga.id)
                } label: {
                  makeResultView(manga: manga)
                }
              }
            }
            .padding(.leading, 24)
            .padding(.trailing, 24)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func makeResultView(
    manga: MangaModel
  ) -> some View {
    HStack(spacing: 8) {
      Image(uiImage: manga.cover ?? UIImage(resource: .coverNotFound))
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 64, height: 128)

      Text(manga.title)
        .font(.footnote)
        .padding(8)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  @ViewBuilder
  private func makeDetailsView(
    _ id: String
  ) -> some View {
    if let viewModel = viewModel.viewModels[id] {
      MangaDetailsView(viewModel: viewModel)
    }

    EmptyView().onAppear {
      print("MangaSearchView Error -> View model not found for \(id)")
    }
  }

}

#Preview {
  MangaSearchView(
    viewModel: MangaSearchView.buildPreviewViewModel()
  )
}

extension MangaSearchView {

  static func buildPreviewViewModel(
  ) -> MangaSearchViewModel {
    let moc = PersistenceController.preview.container.viewContext

    return MangaSearchViewModel(
      datasource: MangaSearchDatasource(
        restRequester: RestRequester(),
        mangaParser: MangaParser(),
        mangaCrud: MangaCrud(),
        viewMoc: moc
      ),
      moc: moc
    )
  }

}
