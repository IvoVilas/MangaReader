//
//  MangaLibraryView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import SwiftUI
import CoreData


struct MangaLibraryView: View {

  enum FilterOptions {
    case display
    case sort
  }

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var scheme
  @Environment(\.refreshLibraryUseCase) private var refreshUseCase

  @StateObject var viewModel: MangaLibraryViewModel

  @State var isLoading = false
  @State var showingFilter = false
  @State var filterOptions = FilterOptions .display
  @State var sheetHeight: CGFloat = .zero

  init(
    coverCrud: CoverCrud = AppEnv.env.coverCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
    appOptionsStore: AppOptionsStore = AppEnv.env.appOptionsStore
  ) {
    _viewModel = StateObject(
      wrappedValue: MangaLibraryViewModel(
        mangasProvider: MangaLibraryProvider(
          coverCrud: coverCrud,
          viewMoc: viewMoc
        ),
        chaptersInfoProvider: ChaptersInfoProvider(viewMoc: viewMoc),
        optionsStore: appOptionsStore
      )
    )
  }

  var body: some View {
    VStack(alignment: .leading) {
      ZStack {
        HStack(spacing: 0) {
          Text("Library")
            .foregroundStyle(scheme.foregroundColor)
            .font(.title)

          Spacer()

          Button { refreshLibrary() } label: {
            Image(systemName: "arrow.clockwise")
              .resizable()
              .scaledToFit()
              .foregroundStyle(scheme.foregroundColor)
              .frame(width: 16, height: 16)
          }

          Spacer().frame(width: 24)

          Button {
            showingFilter.toggle()
          } label: {
            Image(systemName: "line.3.horizontal.decrease")
              .resizable()
              .scaledToFit()
              .foregroundStyle(scheme.foregroundColor)
              .frame(width: 20, height: 20)
          }
        }

        ProgressView()
          .controlSize(.regular)
          .progressViewStyle(.circular)
          .opacity(isLoading ? 1 : 0)
          .offset(y: isLoading ? 0 : -75)
          .animation(.easeInOut, value: isLoading)
      }

      ZStack {
        ScrollView {
          resultCollectionView()
        }
        .scrollIndicators(.hidden)
        .opacity(viewModel.mangas.count > 0 ? 1 : 0)

        VStack(spacing: 8) {
          Image(systemName: "books.vertical")
            .resizable()
            .scaledToFit()
            .foregroundStyle(scheme.secondaryColor)
            .frame(width: 150)

          Text("Your library is emtpy")
            .foregroundStyle(scheme.secondaryColor)
            .font(.title3)
        }
        .opacity(viewModel.mangas.count > 0 ? 0 : 1)
      }
    }
    .background(scheme.backgroundColor)
    .sheet(isPresented: $showingFilter) {
      VStack(spacing: 0) {
        Spacer().frame(height: 16)

        HStack(spacing: 0) {
          Spacer()

          Button { filterOptions = .display } label: {
            Text("Display")
              .foregroundStyle(
                filterOptions == .display ?
                  .blue : scheme.foregroundColor
              )
          }

          Spacer().frame(maxWidth: 36)

          Button { filterOptions = .sort } label: {
            Text("Sort   ")
              .foregroundStyle(
                filterOptions == .sort ?
                  .blue : scheme.foregroundColor
              )
          }

          Spacer()
        }

        Spacer().frame(height: 16)

        Divider()

        switch filterOptions {
        case .display:
          displayOptionsView()
        case .sort:
          sortOptionsView()
        }
      }
      .overlay {
        GeometryReader { geometry in
          Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
        }
      }
      .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
        sheetHeight = newHeight
      }
      .presentationCornerRadius(16)
      .presentationDetents([.height(sheetHeight)])
      .animation(.spring(duration: 0.3), value: filterOptions)
    }
  }

  private func refreshLibrary() {
    Task(priority: .background) {
      await MainActor.run { isLoading = true }

      await refreshUseCase.refresh()

      await MainActor.run { isLoading = false }
    }
  }

}

// MARK: Collection
private extension MangaLibraryView {

  @ViewBuilder
  private func resultCollectionView() -> some View {
    if viewModel.layout.isList {
      LazyVStack(spacing: 16) {
        ForEach(viewModel.mangas) { result in
          Button {
            router.navigate(using: MangaDetailsNavigator(manga: result.manga))
          } label: {
            MangaResultItemView(
              id: result.manga.id,
              cover: result.manga.cover,
              title: result.manga.title,
              unreadChapters: result.unreadChapters,
              textColor: scheme.foregroundColor,
              layout: $viewModel.layout
            )
            .equatable()
          }
        }
      }
    } else {
      LazyVGrid(
        columns:  Array(
          repeating: GridItem(.flexible(), spacing: 16),
          count: Int(viewModel.gridSize)
        ),
        spacing: 16
      ) {
        ForEach(viewModel.mangas) { result in
          Button {
            router.navigate(using: MangaDetailsNavigator(manga: result.manga))
          } label: {
            MangaResultItemView(
              id: result.manga.id,
              cover: result.manga.cover,
              title: result.manga.title,
              unreadChapters: result.unreadChapters,
              textColor: scheme.foregroundColor,
              layout: $viewModel.layout
            )
            .equatable()
          }
        }
      }
    }
  }

}

// MARK: Display Options
private extension MangaLibraryView {

  @ViewBuilder
  private func displayOptionsView() -> some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 16) {
        Text("Display mode")

        HStack(spacing: 0) {
          layoutTagView(.list)

          Spacer()
            .frame(maxWidth: 16)

          layoutTagView(.normal)

          Spacer()
            .frame(maxWidth: 16)

          layoutTagView(.compact)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      HStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Grid size")

          Text("\(Int(viewModel.gridSize))")
            .font(.footnote)
        }

        Slider(
          value: $viewModel.gridSize,
          in: 1...10,
          step: 1
        )
      }
      .opacity(viewModel.layout.isGrid ? 1 : 0)
      .animation(.snappy(duration: 0.1), value: viewModel.layout)
    }
    .padding(.horizontal, 24)
    .padding(.top, 24)
    .padding(.bottom, 48)
  }

  @ViewBuilder
  private func sortOptionsView() -> some View {
    VStack(spacing: 24) {
      sortByOptionView(.title)

      sortByOptionView(.totalChapters)

      sortByOptionView(.unreadCount)

      sortByOptionView(.latestChapter)
    }
    .padding(.horizontal, 24)
    .padding(.top, 24)
    .padding(.bottom, 48)
  }

  @ViewBuilder
  private func layoutTagView(
    _ layout: CollectionLayout
  ) -> some View {
    Button { viewModel.changeLayout(to: layout) } label: {
      Text(layout.name)
        .font(.footnote)
        .lineLimit(1)
        .foregroundStyle(scheme.foregroundColor)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(
              viewModel.layout == layout ?
              scheme.terciaryColor : .clear
            )
            .stroke(
              .gray,
              lineWidth: viewModel.layout == layout ? 0 : 1
            )
        )
    }
  }

  @ViewBuilder
  private func sortByOptionView(
    _ sortBy: MangasSortBy
  ) -> some View {
    Button { viewModel.changeSortBy(to: sortBy) } label: {
      HStack(spacing: 24) {
        Image(systemName: "arrow.up")
          .opacity(viewModel.sortOrder.sortBy == sortBy ? 1 : 0)
          .rotationEffect(.degrees(viewModel.sortOrder.ascending ? 0 : 180))

        Text(sortBy.description)
          .foregroundStyle(scheme.foregroundColor)

        Spacer()
      }
    }
  }

}

private struct InnerHeightPreferenceKey: PreferenceKey {

  static let defaultValue: CGFloat = .zero

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }

}

// MARK: Item
private struct MangaResultItemView: View, Equatable {

  let id: String
  let cover: Data?
  let title: String
  let unreadChapters: Int
  let textColor: Color

  @Binding var layout: CollectionLayout

  static func == (lhs: MangaResultItemView, rhs: MangaResultItemView) -> Bool {
    guard
      lhs.id == rhs.id,
      lhs.unreadChapters == rhs.unreadChapters,
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
        foregroundColor: textColor
      )
      .overlay(alignment: .topLeading) {
        Text("\(unreadChapters)")
          .font(.footnote)
          .lineLimit(1)
          .foregroundStyle(.white)
          .padding(4)
          .background(.blue)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .padding(.leading, 8)
          .padding(.top, 8)
          .opacity(unreadChapters > 0 ? 1 : 0)
      }

    case .compact:
      MangaCompactResultView(
        title: title,
        cover: cover,
        foregroundColor: textColor
      )
      .overlay(alignment: .topLeading) {
        Text("\(unreadChapters)")
          .font(.footnote)
          .lineLimit(1)
          .foregroundStyle(.white)
          .padding(4)
          .background(.blue)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .padding(.leading, 8)
          .padding(.top, 8)
          .opacity(unreadChapters > 0 ? 1 : 0)
      }

    case .list:
      MangaListResultView(
        title: title,
        cover: cover,
        foregroundColor: textColor
      ) {
        Text("\(unreadChapters)")
          .font(.footnote)
          .lineLimit(1)
          .foregroundStyle(.white)
          .padding(4)
          .background(.blue)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .padding(.leading, 8)
          .padding(.top, 8)
          .opacity(unreadChapters > 0 ? 1 : 0)
      }
    }
  }

}

// MARK: Preview
#Preview {
  MangaLibraryView(
    viewMoc: PersistenceController.preview.container.viewContext
  )
}
