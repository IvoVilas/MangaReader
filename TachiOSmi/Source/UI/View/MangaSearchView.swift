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
  @State private var showAlert = false

  var body: some View {
    NavigationStack {
      VStack {
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

          List(viewModel.results) { result in
            NavigationLink(value: result) {
              makeResultView(manga: result)
                .onAppear {
                  if result.id == viewModel.results.last?.id {
                    viewModel.loadNext()
                  }
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
          }
          .scrollContentBackground(.hidden)
          .navigationDestination(for: MangaModel.self) { manga in
            MangaDetailsView(viewModel: viewModel.buildMangaDetailsViewModel(manga))
          }
          .onReceive(viewModel.$error) { error in
            if error != nil {
              showAlert.toggle()
            }
          }
          .alert(
            "Error",
            isPresented: $showAlert,
            presenting: viewModel.error,
            actions: { _ in }
          ) { error in
            Text(error.localizedDescription)
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
        httpClient: HttpClient(),
        mangaParser: MangaParser(),
        mangaCrud: MangaCrud(),
        viewMoc: moc
      ),
      moc: moc
    )
  }

}
