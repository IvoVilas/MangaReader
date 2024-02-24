//
//  MangaReaderView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import SwiftUI
import Combine

struct MangaReaderView: View {

  @ObservedObject var viewModel: MangaReaderViewModel

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .center) {
        ProgressView()
          .progressViewStyle(.circular)
          .tint(.white)
          .opacity(viewModel.pages.count == 0 ? 1 : 0)

        ScrollView(.horizontal) {
          HStack(spacing: 0) {
            ForEach(viewModel.pages) { page in
              makePage(page)
                .frame(width: geo.size.width)
                .frame(maxWidth: geo.size.width, maxHeight: .infinity, alignment: .center)
            }
          }
        }
        .scrollTargetBehavior(.paging)
        .task { await viewModel.makePagesRequest() }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    .background(.black)
    .environment(\.layoutDirection, .rightToLeft)
  }

  @ViewBuilder
  private func makePage(
    _ page: MangaReaderViewModel.Page
  ) -> some View {
    switch page {
    case .remote(let url):
      ImageView(url: url)

    case .notFound:
      Image(uiImage: .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }

}

struct ImageView: View {

  @State var url: URL

  var body: some View {
    AsyncImage(url: url) { image in
      image
        .resizable()
        .aspectRatio(contentMode: .fit)
    } placeholder: {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
    }
  }

}

#Preview {
  MangaReaderView(
    viewModel: MangaReaderViewModel(
      chapterId: "97e84c86-e3cd-416d-998d-3b4c732e317d",
      httpClient: HttpClient()
    )
  )
}
