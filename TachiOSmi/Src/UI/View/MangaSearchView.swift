//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI
import CoreData
import WebKit

// MARK: Search
struct MangaSearchView: View {

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var scheme

  @StateObject var viewModel: MangaSearchViewModel
  @State private var toast: Toast?

  init(
    source: Source,
    mangaCrud: MangaCrud = AppEnv.env.mangaCrud,
    coverCrud: CoverCrud = AppEnv.env.coverCrud,
    httpClient: HttpClientType = AppEnv.env.httpClient,
    appOptionsStore: AppOptionsStore = AppEnv.env.appOptionsStore,
    container: NSPersistentContainer = PersistenceController.shared.container
  ) {
    _viewModel = StateObject(
      wrappedValue: MangaSearchViewModel(
        source: source,
        mangaCrud: mangaCrud,
        coverCrud: coverCrud,
        httpClient: httpClient,
        optionsStore: appOptionsStore,
        container: container
      )
    )
  }

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
        changeLayout: viewModel.toggleLayout,
        input: $viewModel.input,
        layout: $viewModel.layout
      )
      .padding(.horizontal, 16)

      ZStack {
        ProgressView()
          .progressViewStyle(.circular)
          .tint(scheme.foregroundColor)
          .opacity(viewModel.isLoading ? 1 : 0)

        ScrollView {
          resultCollectionView()
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .opacity(viewModel.isLoading ? 0 : 1)
        .task(priority: .medium) {
          if viewModel.results.isEmpty {
            await viewModel.doSearch()
          }
        }
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
    .background(scheme.backgroundColor)
    .navigationBarBackButtonHidden(true)
  }

  @ViewBuilder
  private func resultCollectionView() -> some View {
    if viewModel.layout.isList {
      LazyVStack(spacing: 16) {
        ForEach(viewModel.results) { result in
          Button {
            router.navigate(using: MangaDetailsNavigator(manga: result))
          } label: {
            MangaResultItemView(
              id: result.id,
              cover: result.cover,
              title: result.title,
              textColor: scheme.foregroundColor,
              isSaved: viewModel.savedMangas.contains(result.id),
              layout: $viewModel.layout
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
    } else {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(viewModel.results) { result in
          Button {
            router.navigate(using: MangaDetailsNavigator(manga: result))
          } label: {
            MangaResultItemView(
              id: result.id,
              cover: result.cover,
              title: result.title,
              textColor: scheme.foregroundColor,
              isSaved: viewModel.savedMangas.contains(result.id),
              layout: $viewModel.layout
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
    }
  }

}

// MARK: Header
private struct HeaderView: View {

  let name: String
  let tintColor: Color
  let textColor: Color
  let doSearch: (() async -> Void)?
  let changeLayout: (() -> Void)?

  @State var didSearch = false
  @State var isSearching: Bool = false
  @Binding var input: String
  @Binding var layout: CollectionLayout
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
        changeLayout?()
      } label: {
        layout.icon.image()
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
private struct MangaResultItemView: View, Equatable {

  let id: String
  let cover: Data?
  let title: String
  let textColor: Color
  let isSaved: Bool

  @Binding var layout: CollectionLayout

  static func == (lhs: MangaResultItemView, rhs: MangaResultItemView) -> Bool {
    guard
      lhs.id == rhs.id,
      lhs.isSaved == rhs.isSaved,
      lhs.textColor == rhs.textColor,
      lhs.layout == rhs.layout,
      lhs.cover == rhs.cover
    else {
      return false
    }
    
    return true
  }

  var body: some View {
    switch layout {
    case .normal:
      MangaResultView(
        title: title,
        cover: cover,
        foregroundColor: textColor,
        coverOpacity: isSaved ? 0.4 : 1
      )
      .overlay(
        Image(systemName: "bookmark.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 15)
          .foregroundStyle(.blue)
          .aspectRatio(1, contentMode: .fill)
          .padding(.leading, 8)
          .opacity(isSaved ? 1 : 0),
        alignment: .topLeading
      )

    case .compact:
      MangaCompactResultView(
        title: title,
        cover: cover,
        foregroundColor: textColor,
        coverOpacity: isSaved ? 0.4 : 1
      )
      .overlay(
        Image(systemName: "bookmark.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 15)
          .foregroundStyle(.blue)
          .aspectRatio(1, contentMode: .fill)
          .padding(.leading, 8)
          .opacity(isSaved ? 1 : 0),
        alignment: .topLeading
      )

    case .list:
      MangaListResultView(
        title: title,
        cover: cover,
        foregroundColor: textColor,
        opacity: isSaved ? 0.4 : 1
      ) {
        Image(systemName: "bookmark.fill")
          .resizable()
          .scaledToFit()
          .frame(height: 16)
          .foregroundStyle(.blue)
          .padding(.leading, 8)
          .opacity(isSaved ? 1 : 0)
      }
    }
  }

}

#Preview {
  MangaSearchView(
    source: .unknown,
    appOptionsStore: AppOptionsStore(keyValueManager: InMemoryKeyValueManager()),
    container: PersistenceController.preview.container
  )
}
