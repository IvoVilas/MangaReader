//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI
import CoreData

// MARK: Search
struct MangaSearchView<Source: SourceType>: View {

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

  @ObservedObject var viewModel: MangaSearchViewModel<Source>
  @State private var toast: Toast?
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
        HeaderView(
          name: Source.name,
          tintColor: foregroundColor,
          textColor: secondaryColor,
          doSearch: viewModel.doSearch,
          input: $viewModel.input
        )
        .padding(.horizontal, 16)

        ZStack {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(secondaryColor)
            .opacity(viewModel.isLoading ? 1 : 0)

          ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
              ForEach(viewModel.results) { result in
                NavigationLink(value: result) {
                  MangaResultCompactView(
                    id: result.id,
                    cover: result.cover,
                    title: result.title,
                    textColor: secondaryColor
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
  @FocusState private var inputFieldIsFocused: Bool

  var body: some View {
    HStack(spacing: 16) {
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
        // do togle
      } label: {
        Image(systemName: "rectangle.grid.3x2.fill")
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

// MARK: ResultCompact
private struct MangaResultCompactView: View, Equatable {

  let id: String
  let cover: Data?
  let title: String
  let textColor: Color

  static func == (lhs: MangaResultCompactView, rhs: MangaResultCompactView) -> Bool {
    if lhs.id != rhs.id { return false }

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
    Image(uiImage: UIImage(data: cover ?? Data()) ?? UIImage())
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

// MARK: Result
private struct MangaResultView: View, Equatable {

  let id: String
  let cover: Data?
  let title: String
  let textColor: Color

  static func == (lhs: MangaResultView, rhs: MangaResultView) -> Bool {
    if lhs.id != rhs.id { return false }

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
    VStack(spacing: 4) {
      Image(uiImage: UIImage(data: cover ?? Data()) ?? UIImage())
        .clipShape(RoundedRectangle(cornerRadius: 8))

      Text(title)
        .font(.caption2)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }

}

#Preview {
  MangaSearchView<MangadexMangaSource>(
    viewModel: MangaSearchViewModel(
      datasource: SearchDatasource(
        delegate: MangadexSearchDelegate(
          httpClient: HttpClient(),
          mangaParser: MangaParser()
        ),
        mangaCrud: MangaCrud(),
        coverCrud: CoverCrud(),
        viewMoc: PersistenceController.preview.mangaDex.viewMoc
      )
    )
  )
}
