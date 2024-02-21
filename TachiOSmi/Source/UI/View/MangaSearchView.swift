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
                  MangaDetailsView(
                    viewModel: viewModel.buildMangaDetailsViewModel(manga)
                  )
                } label: {
                  makeResultView(manga: manga)
                }
              }
            }
            .padding(.leading, 24)
            .padding(.trailing, 24)
            .opacity(viewModel.results.isEmpty || viewModel.isLoading ? 0 : 1)
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

}

//struct NavigationLazyView<Content: View>: View {
//  let build: () -> Content
//
//  init(_ build: @autoclosure @escaping () -> Content) {
//    self.build = build
//  }
//
//  var body: Content {
//    build()
//  }
//
//}

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
        mangaParser: MangaParser(),
        mangaCrud: MangaCrud(),
        moc: moc
      ),
      moc: moc
    )
  }

}
