//
//  MangaLibraryView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import SwiftUI
import CoreData

struct MangaLibraryView: View {
  
  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var scheme
  @Environment(\.refreshLibraryUseCase) private var refreshUseCase

  @StateObject var provider: MangaLibraryProvider
  @State var isLoading = false
  @State var layout: CollectionLayout = .compact

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: 16),
    count: 3
  )

  init(
    coverCrud: CoverCrud = AppEnv.env.coverCrud,
    chapterCrud: ChapterCrud = AppEnv.env.chapterCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    _provider = StateObject(
      wrappedValue: MangaLibraryProvider(
        coverCrud: coverCrud,
        chapterCrud: chapterCrud,
        viewMoc: viewMoc
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
            layout = layout.toggle()
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
        .opacity(provider.mangas.count > 0 ? 1 : 0)

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
        .opacity(provider.mangas.count > 0 ? 0 : 1)
      }
    }
    .background(scheme.backgroundColor)
  }

  @ViewBuilder
  private func resultCollectionView() -> some View {
    if layout == .list {
      LazyVStack(spacing: 16) {
        ForEach(provider.mangas) { result in
          Button {
            router.navigate(using: MangaDetailsNavigator.fromMangaWrapper(result))
          } label: {
            MangaResultItemView(
              id: result.manga.id,
              cover: result.manga.cover,
              title: result.manga.title,
              unreadChapters: result.unreadChapters,
              textColor: scheme.foregroundColor,
              layout: $layout
            )
            .equatable()
          }
        }
      }
    } else {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(provider.mangas) { result in
          Button {
            router.navigate(using: MangaDetailsNavigator.fromMangaWrapper(result))
          } label: {
            MangaResultItemView(
              id: result.manga.id,
              cover: result.manga.cover,
              title: result.manga.title,
              unreadChapters: result.unreadChapters,
              textColor: scheme.foregroundColor,
              layout: $layout
            )
            .equatable()
          }
        }
      }
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

#Preview {
  MangaLibraryView(
    viewMoc: PersistenceController.preview.container.viewContext
  )
}
