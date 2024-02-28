//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI
import CoreData

struct MangaSearchView: View {

  enum ResultLayout {
    case normal
    case compact

    var iconName: String {
      switch self {
      case .normal:
        "rectangle.grid.3x2.fill"
      case .compact:
        "square.grid.3x3.fill"
      }
    }

    func toggle() -> ResultLayout {
      switch self {
      case .normal:
        return .compact

      case .compact:
        return .normal
      }
    }
  }

  @ObservedObject var viewModel: MangaSearchViewModel

  @FocusState private var inputFieldIsFocused: Bool

  @State private var toast: Toast?
  @State private var didSearch = false
  @State private var isSearching = false
  @State private var listLayout = ResultLayout.compact

  private let backgroundColor = Color.white
  private let foregroundColor = Color.gray
  private let secondaryColor  = Color.black

  let columns = Array(
    repeating: GridItem(.flexible(), spacing: 16),
    count: 3
  )

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        makeHeaderView()
          .padding(.horizontal, 16)

        Divider()
          .background(secondaryColor)

        ZStack {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(secondaryColor)
            .opacity(viewModel.isLoading ? 1 : 0)

          ScrollView {
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
          .opacity(viewModel.isLoading ? 0 : 1)
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
      .background(backgroundColor)
    }
  }

  @ViewBuilder
  private func makeHeaderView() -> some View {
    HStack(spacing: 16) {
      ZStack(alignment: .leading) {
        Text("MangaDex")
          .foregroundStyle(foregroundColor)
          .font(.title)
          .padding(.vertical, 16)
          .opacity(isSearching ? 0 : 1)

        TextField(
          "",
          text: $viewModel.input,
          prompt: Text("Search title...")
            .font(.title3)
            .foregroundStyle(foregroundColor)
        )
        .keyboardType(.default)
        .focused($inputFieldIsFocused)
        .foregroundStyle(secondaryColor)
        .textInputAutocapitalization(.sentences)
        .autocorrectionDisabled(true)
        .padding(.vertical, 8)
        .onSubmit {
          didSearch = true

          Task(priority: .medium) {
            await viewModel.doSearch()
          }
        }
        .submitLabel(.search)
        .opacity(isSearching ? 1 : 0)
      }

      Spacer()

      Button { searchAction() } label: {
        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
          .tint(foregroundColor)
      }

      Button {
        listLayout = listLayout.toggle()
      } label: {
        Image(systemName: listLayout.iconName)
          .tint(foregroundColor)
      }
    }
  }

  @ViewBuilder
  private func makeResultView(
    manga: MangaModel
  ) -> some View {
    switch listLayout {
    case .normal:
      VStack(spacing: 4) {
        Image(uiImage: getCoverImage(manga))
          .resizable()
          .aspectRatio(0.625, contentMode: .fill)
          .clipShape(RoundedRectangle(cornerRadius: 8))

        Text(manga.title)
          .font(.caption2)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .foregroundStyle(secondaryColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }

    case .compact:
      Image(uiImage: getCoverImage(manga))
        .resizable()
        .aspectRatio(0.625, contentMode: .fill)
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

  private func searchAction() {
    if isSearching {
      viewModel.input = ""
      isSearching.toggle()

      if didSearch {
        Task(priority: .medium) {
          await viewModel.doSearch()
        }
      }

      inputFieldIsFocused = false
      didSearch = false
    } else {
      isSearching.toggle()
      inputFieldIsFocused = true
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
        coverCrud: CoverCrud(),
        viewMoc: moc
      ),
      moc: moc
    )
  }

}
