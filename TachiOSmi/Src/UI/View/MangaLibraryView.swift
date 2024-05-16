//
//  MangaLibraryView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import SwiftUI
import CoreData

struct MangaLibraryView: View {
  
  @Environment(\.colorScheme) private var scheme

  @StateObject var provider: MangaLibraryProvider

  private let getNavigator: (MangaLibraryProvider.MangaWrapper) -> MangaDetailsNavigator

  init(
    coverCrud: CoverCrud = AppEnv.env.coverCrud,
    chapterCrud: ChapterCrud = AppEnv.env.chapterCrud,
    viewMoc: NSManagedObjectContext
  ) {
    getNavigator = {
      MangaDetailsNavigator(
        source: $0.source,
        manga: $0.manga,
        viewMoc: viewMoc,
        moc: PersistenceController.shared.container.newBackgroundContext()
      )
    }

    _provider = StateObject(
      wrappedValue: MangaLibraryProvider(
        coverCrud: coverCrud,
        chapterCrud: chapterCrud,
        viewMoc: viewMoc
      )
    )
  }

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: 16),
    count: 3
  )
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Library")
        .foregroundStyle(scheme.foregroundColor)
        .font(.title)
      
      ZStack {
        ScrollView {
          LazyVGrid(columns: columns, spacing: 16) {
            ForEach(provider.mangas) { result in
              NavigationLink(value: getNavigator(result)) {
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
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.leading, 8)
        .padding(.top, 8)
        .opacity(manga.unreadChapters > 0 ? 1 : 0)
    }
  }
  
}

#Preview {
  MangaLibraryView(
    viewMoc: PersistenceController.preview.container.viewContext
  )
}
