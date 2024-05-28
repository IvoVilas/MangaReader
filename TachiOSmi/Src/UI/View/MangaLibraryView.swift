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
        HStack {
          Text("Library")
            .foregroundStyle(scheme.foregroundColor)
            .font(.title)

          Spacer()

          Button { refreshLibrary() } label: {
            Image(systemName: "arrow.clockwise")
              .foregroundStyle(scheme.foregroundColor)
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
          LazyVGrid(columns: columns, spacing: 16) {
            ForEach(provider.mangas) { result in
              Button {
                router.navigate(using: MangaDetailsNavigator.fromMangaWrapper(result))
              } label: {
                makeMangaView(result)
              }
            }
          }
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
  private func makeMangaView(
    _ manga: MangaLibraryProvider.MangaWrapper
  ) -> some View {
    ZStack(alignment: .topLeading) {
      Image(uiImage: manga.manga.cover.toUIImage() ?? UIImage())
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
            
            Text(manga.manga.title)
              .font(.footnote)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
              .foregroundStyle(.white)
              .padding(.horizontal, 4)
              .padding(.bottom, 8)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
      
      Text("\(manga.unreadChapters)")
        .font(.footnote)
        .lineLimit(1)
        .foregroundStyle(.white)
        .padding(4)
        .background(.blue)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.leading, 8)
        .padding(.top, 8)
        .opacity(manga.unreadChapters > 0 ? 1 : 0)
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

#Preview {
  MangaLibraryView(
    viewMoc: PersistenceController.preview.container.viewContext
  )
}
