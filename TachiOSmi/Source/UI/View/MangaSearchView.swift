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
  @State private var toast: Toast?

  let columns = Array(
    repeating: GridItem(.flexible(), spacing: 16),
    count: 3
  )

  var body: some View {
    NavigationStack {
      MangaSearchHeaderView(
        viewModel: viewModel
      )

      ScrollView {
        ProgressView()
          .progressViewStyle(.circular)
          .opacity(viewModel.isLoading ? 1 : 0)

        LazyVGrid(columns: columns) {
          ForEach(viewModel.results) { result in
            NavigationLink(value: result) {
              makeResultView(manga: result)
                .onAppear {
                  Task(priority: .medium) {
                    await viewModel.loadNextIfNeeded(result.id)
                  }
                }
            }
          }
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
      .refreshable {
        Task(priority: .medium) {
          await viewModel.doSearch()
        }
      }
      .onAppear {
        Task(priority: .medium) {
          if viewModel.results.isEmpty {
            await viewModel.doSearch()
          }
        }
      }
      .navigationDestination(for: MangaModel.self) { manga in
        MangaDetailsView(viewModel: viewModel.buildMangaDetailsViewModel(manga))
      }
      .toastView(toast: $toast)
      .onReceive(viewModel.$error) { error in
        if let error {
          toast = Toast(
            style: .error,
            message: error.localizedDescription
          )
        }
      }
    }
  }

  @ViewBuilder
  private func makeResultView(
    manga: MangaModel
  ) -> some View {
    Image(uiImage: getCoverImage(manga))
      .resizable()
      .aspectRatio(contentMode: .fill)
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
  }

  private func getCoverImage(
    _ manga: MangaModel
  ) -> UIImage {
    if let data = manga.cover, let cover = UIImage(data: data) {
      return cover
    }

    return UIImage.coverNotFound
  }

}

struct MangaSearchHeaderView: View {

  @ObservedObject var viewModel: MangaSearchViewModel
  @FocusState private var inputFieldIsFocused: Bool

  var body: some View {
    HStack(spacing: 16) {
      Button {
        // Do back action
      } label: {
        Image(systemName: "arrow.left")
          .tint(.gray)
      }

      TextField(
        "Manga title",
        text: $viewModel.input
      )
      .keyboardType(.default)
      .focused($inputFieldIsFocused)
      .textInputAutocapitalization(.sentences)
      .autocorrectionDisabled(true)
      .padding(.vertical, 8)
      .onSubmit {
        Task(priority: .medium) {
          await viewModel.doSearch()
        }
      }
      .submitLabel(.search)

      Button {
        viewModel.input = ""
      } label: {
        Image(systemName: "xmark")
          .tint(.gray)
      }

      Button {
        // Do layout action
      } label: {
        Image(systemName: "rectangle.grid.3x2.fill")
          .tint(.gray)
      }
    }
    .padding(.horizontal, 16)
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
        coverCrud: CoverCrud(),
        viewMoc: moc
      ),
      moc: moc
    )
  }

}
