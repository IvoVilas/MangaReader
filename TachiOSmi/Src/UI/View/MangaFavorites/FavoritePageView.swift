//
//  FavoritePageView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 29/10/2024.
//

import SwiftUI

struct FavoritePageView: View {

  @Environment(\.colorScheme) private var scheme
  @Environment(\.router) private var router

  @State var page: StoredPageModel?
  var namespace: Namespace.ID
  var onGoToChapter: (StoredPageModel?) -> Void
  var onDismiss: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.1)
        .ignoresSafeArea()
        .onTapGesture {
          onDismiss()
        }

      ZStack {
        ScrollView {
          Spacer().frame(height: 72)

          if let page, let data = page.data, let uiImage = UIImage(data: data) {
            ZoomableImageView(image: uiImage, allowsZoom: true)
              .matchedGeometryEffect(id: page.pageId, in: namespace)
              .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height - 200)
              .zIndex(1)
              .clipShape(RoundedRectangle(cornerRadius: 12))
          }
        }
        .scrollIndicators(.hidden)

        VStack(alignment: .leading, spacing: 8) {
          Button { onDismiss() } label: {
            Image(systemName: "xmark")
              .font(.headline)
              .tint(scheme.foregroundColor)
              .padding(.top, 24)
              .padding(.leading, 16)
          }

          Spacer()

          goToChapterView()
        }
      }
    }
  }

  @ViewBuilder
  private func goToChapterView() -> some View {
    HStack(spacing: 0) {
      Spacer()

      Button { onGoToChapter(page) } label: {
        HStack(spacing: 8) {
          Text("Open chapter")
            .tint(scheme.foregroundColor)

          Image(systemName: "arrow.right")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .tint(scheme.foregroundColor)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(scheme.terciaryColor)
        .clipShape(Capsule())
      }

      Spacer()
    }
  }

}

#Preview {
  FavoritePageView(
    page: StoredPageModel(
      pageId: "1",
      mangaId: "1",
      chapterId: "1",
      pageNumber: 1,
      source: .unknown,
      isFavorite: true,
      downloadInfo: "1",
      filePath: nil,
      data: UIImage.jujutsuPage.pngData()
    ),
    namespace: Namespace.init().wrappedValue,
    onGoToChapter: { _ in },
    onDismiss: { }
  )
}
