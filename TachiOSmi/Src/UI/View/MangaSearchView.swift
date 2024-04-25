//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI
import CoreData

// MARK: Layout
private enum ResultLayout {
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

// MARK: Search
struct MangaSearchView: View {

  @Environment(\.colorScheme) private var scheme

  @Bindable var viewModel: MangaSearchViewModel
  @State private var toast: Toast?
  @State private var listLayout = ResultLayout.compact

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: 16),
    count: 3
  )

  var body: some View {
    VStack(spacing: 0) {
      HeaderView(
        name: viewModel.sourceName,
        tintColor: scheme.secondaryColor,
        textColor: scheme.foregroundColor,
        doSearch: viewModel.doSearch,
        input: $viewModel.input,
        layout: $listLayout
      )
      .padding(.horizontal, 16)

      ZStack {
        ProgressView()
          .progressViewStyle(.circular)
          .tint(scheme.foregroundColor)
          .opacity(viewModel.isLoading ? 1 : 0)

        ScrollView {
          LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.results) { result in
              NavigationLink(value: result) {
                MangaResultView(
                  id: result.id,
                  cover: result.cover,
                  title: result.title,
                  textColor: scheme.foregroundColor,
                  isSaved: result.isSaved,
                  layout: $listLayout
                )
                .equatable()
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
        .task(priority: .medium) {
          if viewModel.results.isEmpty {
            await viewModel.doSearch()
          }
        }
      }
      .navigationDestination(for: MangaSearchResult.self) { manga in
        MangaDetailsView(viewModel: viewModel.buildMangaDetailsViewModel(manga))
      }
      .toastView(toast: $toast)
      .onChange(of: viewModel.error) { _, error in
        if let error {
          toast = Toast(
            style: .error,
            message: error.localizedDescription
          )
        }
      }
    }
    .background(scheme.backgroundColor)
    .navigationBarBackButtonHidden(true)
  }

}

// MARK: Header
private struct HeaderView: View {

  let name: String
  let tintColor: Color
  let textColor: Color
  let doSearch: (() async -> Void)?

  @State var didSearch = false
  @State var isSearching: Bool = false
  @Binding var input: String
  @Binding var layout: ResultLayout
  @FocusState private var inputFieldIsFocused: Bool

  var body: some View {
    HStack(spacing: 16) {
      CustomBackAction(tintColor: tintColor)

      ZStack(alignment: .leading) {
        Text(name)
          .foregroundStyle(tintColor)
          .font(.title)
          .padding(.vertical, 16)
          .opacity(isSearching ? 0 : 1)

        TextField(
          "",
          text: $input,
          prompt: Text("Search title...")
            .font(.title3)
            .foregroundStyle(tintColor)
        )
        .keyboardType(.default)
        .focused($inputFieldIsFocused)
        .foregroundStyle(textColor)
        .textInputAutocapitalization(.sentences)
        .autocorrectionDisabled(true)
        .padding(.vertical, 8)
        .onSubmit {
          Task(priority: .medium) {
            didSearch = true

            await doSearch?()
          }
        }
        .submitLabel(.search)
        .opacity(isSearching ? 1 : 0)
      }

      Spacer()

      Button { searchAction() } label: {
        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
          .tint(tintColor)
      }

      Button {
        layout = layout.toggle()
      } label: {
        Image(systemName: layout.iconName)
          .tint(tintColor)
      }
    }
  }

  private func searchAction() {
    input = ""

    if didSearch {
      didSearch = false

      Task(priority: .medium) { await doSearch?() }
    }

    isSearching.toggle()

    inputFieldIsFocused = isSearching
  }

}

// MARK: Result
private struct MangaResultView: View, Equatable {

  let id: String
  let cover: Data?
  let title: String
  let textColor: Color
  let isSaved: Bool

  @Binding var layout: ResultLayout

  static func == (lhs: MangaResultView, rhs: MangaResultView) -> Bool {
    if lhs.id != rhs.id { return false }

    if lhs.isSaved != rhs.isSaved { return false }

    switch (lhs.cover, rhs.cover) {
    case (.none, .some):
      return false

    case (.some, .none):
      return false

    default:
      return true
    }
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      makeResultView()
        .overlay(
          .white.opacity(isSaved ? 0.5 : 0)
        )

      Image(systemName: "bookmark.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 15)
        .foregroundStyle(.black)
        .aspectRatio(1, contentMode: .fill)
        .padding(.leading, 8)
        .opacity(isSaved ? 1 : 0)
    }
  }

  // We should avoid using conditional views
  // Specially on a view that is drawn so many times like this one
  @ViewBuilder
  private func makeResultView() -> some View {
    switch layout {
    case .normal:
      VStack(alignment: .leading, spacing: 4) {
        Image(uiImage: cover.toUIImage() ?? UIImage())
          .resizable()
          .aspectRatio(0.625, contentMode: .fill)
          .background(.gray)
          .clipShape(RoundedRectangle(cornerRadius: 8))

        Text(title)
          .font(.caption2)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .foregroundStyle(textColor)
          .frame(maxHeight: .infinity, alignment: .topLeading)
      }

    case .compact:
      Image(uiImage: cover.toUIImage() ?? UIImage())
        .resizable()
        .aspectRatio(0.625, contentMode: .fill)
        .background(.gray)
        .overlay {
          ZStack(alignment: .bottomLeading) {
            LinearGradient(
              gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
              startPoint: .center,
              endPoint: .bottom
            )

            Text(title)
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

}

#Preview {
  MangaSearchView(
    viewModel: MangaSearchViewModel(
      source: .mangadex,
      mangaCrud: MangaCrud(),
      coverCrud: CoverCrud(),
      httpClient: HttpClient(),
      viewMoc: PersistenceController.preview.container.viewContext
    )
  )
}

#Preview {
  MangaResultView(
    id: "1",
    cover: UIImage.jujutsuCover.pngData(),
    title: "Jujutsu Kaisen",
    textColor: .black,
    isSaved: true,
    layout: .constant(.compact)
  )
  .frame(width: 120, height: 0)
}
