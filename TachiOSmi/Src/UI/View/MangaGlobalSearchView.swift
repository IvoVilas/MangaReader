//
//  MangaGlobalSearchView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import SwiftUI
import CoreData

struct MangaGlobalSearchView: View {

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var scheme

  @FocusState private var inputFieldIsFocused: Bool

  @StateObject private var viewModel: MangaGlobalSearchViewModel

  init(
    mangaCrud: MangaCrud = AppEnv.env.mangaCrud,
    coverCrud: CoverCrud = AppEnv.env.coverCrud,
    httpClient: HttpClientType = AppEnv.env.httpClient,
    appOptionsStore: AppOptionsStore = AppEnv.env.appOptionsStore,
    container: NSPersistentContainer = PersistenceController.shared.container
  ) {
    _viewModel = StateObject(
      wrappedValue: MangaGlobalSearchViewModel(
        mangaCrud: mangaCrud,
        coverCrud: coverCrud,
        httpClient: httpClient,
        container: container
      )
    )
  }

  var body: some View {
    VStack(spacing: 16) {
      headerView()
        .padding(.horizontal, 16)

      ScrollView {
        VStack(spacing: 24) {
          ForEach(viewModel.sources) { sourceViewModel in
            SourceSearchResultsView(
              viewModel: sourceViewModel,
              savedMangas: $viewModel.savedMangas,
              foregroundColor: scheme.foregroundColor
            )
          }
        }
      }
    }
    .scrollDismissesKeyboard(.interactively)
    .toolbar(.hidden, for: .navigationBar)
  }

  @ViewBuilder
  private func headerView() -> some View {
    HStack(spacing: 16) {
      CustomBackAction(tintColor: scheme.secondaryColor)

      TextField(
        "",
        text: $viewModel.input,
        prompt: Text("Search title...")
          .font(.title3)
          .foregroundStyle(scheme.secondaryColor)
      )
      .keyboardType(.default)
      .focused($inputFieldIsFocused)
      .foregroundStyle(scheme.foregroundColor)
      .textInputAutocapitalization(.sentences)
      .autocorrectionDisabled(true)
      .padding(.vertical, 8)
      .onSubmit { viewModel.doSearch() }
      .submitLabel(.search)

      Spacer()

      Button {
        viewModel.input = ""
        inputFieldIsFocused = true
      } label: {
        Image(systemName: "xmark")
          .tint(scheme.secondaryColor)
          .opacity(viewModel.input.isEmpty ? 0 : 1)
      }
    }
  }

}

private struct SourceSearchResultsView: View {

  @Environment(\.router) private var router

  @ObservedObject var viewModel: SourceResultsViewModel
  @Binding var savedMangas: [String]

  let foregroundColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button {
        router.navigate(
          using: MangaLoadedSearchNavigator(
            input: viewModel.input,
            datasource: viewModel.datasource
          )
        )
      } label: {
        HStack(spacing: 8) {
          Image(uiImage: viewModel.source.logo)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 8))

          VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.source.name)
              .font(.subheadline)
              .foregroundStyle(foregroundColor)

            Text("English")
              .font(.caption2)
              .foregroundStyle(foregroundColor)

          }

          Spacer()

          Image(systemName: "arrow.right")
            .tint(foregroundColor)
        }
      }
      .padding(.horizontal, 16)

      ZStack {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 8) {
            ForEach(viewModel.results) { result in
              Button {
                router.navigate(using: MangaDetailsNavigator(manga: result))
              } label: {
                MangaCompactResultView(
                  title: result.title,
                  cover: result.cover,
                  foregroundColor: foregroundColor,
                  coverOpacity: savedMangas.contains(result.id) ? 0.4 : 1
                )
                .overlay(
                  Image(systemName: "bookmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15)
                    .foregroundStyle(.blue)
                    .aspectRatio(1, contentMode: .fill)
                    .padding(.leading, 8)
                    .opacity(savedMangas.contains(result.id) ? 1 : 0),
                  alignment: .topLeading
                )
              }
            }
          }
          .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .opacity(viewModel.isLoading ? 0 : 1)

        ProgressView()
          .progressViewStyle(.circular)
          .opacity(viewModel.isLoading ? 1 : 0)

        Text("No results found")
          .font(.caption2)
          .foregroundStyle(foregroundColor)
          .opacity(viewModel.results.isEmpty && !viewModel.isLoading ? 1 : 0)
      }
      .frame(
        height: getContentHeight(
          hasResults: !viewModel.results.isEmpty,
          isLoading: viewModel.isLoading
        )
      )
    }
    //.frame(height: viewModel.results.isEmpty && !viewModel.isLoading ? 0 : nil)
    //.opacity(viewModel.results.isEmpty && !viewModel.isLoading ? 0 : 1)
    // these conditions are wrong (viewModels will need a state), same for getContentHeight
  }

  private func getContentHeight(
    hasResults: Bool,
    isLoading: Bool
  ) -> CGFloat {
    if isLoading {
      return 50
    }

    if hasResults {
      return 150
    }

    return 0
  }

}

#Preview {
  MangaGlobalSearchView(
    container: PersistenceController.preview.container
  )
}
