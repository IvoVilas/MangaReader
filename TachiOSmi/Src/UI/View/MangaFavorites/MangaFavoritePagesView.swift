//
//  MangaFavoritePagesView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/10/2024.
//

import SwiftUI
import CoreData

struct MangaFavoritePagesView: View {

  @Environment(\.colorScheme) private var scheme
  @Environment(\.router) private var router

  @StateObject var viewModel: MangaFavoritePagesViewModel
  @State private var selectedPage: StoredPageModel?
  @Namespace private var namespace

  init(
    mangaPages: MangaFavoritePages,
    mangaCrud: MangaCrud = AppEnv.env.mangaCrud,
    chapterCrud: ChapterCrud = AppEnv.env.chapterCrud,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    _viewModel = StateObject(
      wrappedValue: MangaFavoritePagesViewModel(
        mangaPages: mangaPages,
        mangaCrud: mangaCrud,
        chapterCrud: chapterCrud,
        viewMoc: viewMoc
      )
    )
  }

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        navbarView()
          .padding(.horizontal, 24)

        ZStack(alignment: .top) {
          ScrollView {
            Spacer().frame(height: 16)

            VStack(spacing: 16) {
              pageView(viewModel.spotlightPage)

              LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                spacing: 16
              ) {
                ForEach(viewModel.pages) { page in
                  pageView(page)
                }
              }
            }
            .padding(.horizontal, 24)
          }
          .scrollIndicators(.hidden)

          LinearGradient(
            gradient: Gradient(colors: [scheme.backgroundColor, .clear]),
            startPoint: .top,
            endPoint: .bottom
          ).frame(height: 8)
        }
      }
      .blur(radius: selectedPage == nil ? 0 : 4)

      if let selectedPage {
        FavoritePageView(page: selectedPage, namespace: namespace) {
          viewModel.navigateToChapter(using: $0, router: router)
        } onDismiss: {
          withAnimation {
            self.selectedPage = nil
          }
        }
        .transition(.opacity)
      }
    }
    .navigationBarBackButtonHidden(true)
  }

  @ViewBuilder
  private func navbarView() -> some View {
    HStack(spacing: 16) {
      CustomBackAction(tintColor: scheme.foregroundColor)
        .frame(width: 20, height: 20)

      Text(viewModel.title)
        .foregroundStyle(scheme.foregroundColor)
        .font(.title)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

}

extension MangaFavoritePagesView {

  @ViewBuilder
  private func pageView(_ page: StoredPageModel?) -> some View {
    if 
      let page,
      let pageData = page.data,
      let uiImage = UIImage(data: pageData)
    {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .background(.gray)
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(scheme.foregroundColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .matchedGeometryEffect(id: page.id, in: namespace, isSource: selectedPage == nil)
        .onTapGesture {
          withAnimation {
            selectedPage = page
          }
        }
    } else {
      Text("Unable to load image")
        .foregroundColor(.red)
    }
  }

}

#Preview {
  MangaFavoritePagesView(
    mangaPages: MangaFavoritePages(
      manga: MangaModel(
        id: "1",
        title: "Jujutsu Kaisen",
        description: nil,
        isSaved: true,
        source: .unknown,
        status: .ongoing,
        readingDirection: .leftToRight,
        cover: UIImage.jujutsuCover.jpegData(compressionQuality: 1),
        tags: [],
        authors: []
      ),
      pages: [
        StoredPageModel(
          pageId: "1",
          mangaId: "1",
          chapterId: "1",
          pageNumber: 1,
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuPage.pngData()
        ),
        StoredPageModel(
          pageId: "2",
          mangaId: "1",
          chapterId: "1",
          pageNumber: 1,
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuPage.pngData()
        ),
        StoredPageModel(
          pageId: "3",
          mangaId: "1",
          chapterId: "1",
          pageNumber: 1,
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuPage.pngData()
        ),
        StoredPageModel(
          pageId: "4",
          mangaId: "1",
          chapterId: "1",
          pageNumber: 1,
          source: .unknown,
          isFavorite: true,
          downloadInfo: "",
          filePath: nil,
          data: UIImage.jujutsuPage.pngData()
        )
      ]
    )
  )
}
