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
            ForEach(Array(viewModel.pages.enumerated()), id:\.offset) { _, viewModel in
              ImageView(viewModel: viewModel)
                .frame(width: geo.size.width)
                .frame(maxWidth: geo.size.width, maxHeight: .infinity, alignment: .center)
            }
          }
        }
        .scrollTargetBehavior(.paging)
        .onAppear { viewModel.viewDidAppear() }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    .background(.black)
    .environment(\.layoutDirection, .rightToLeft)
  }

}

struct ImageView: View {

  @ObservedObject var viewModel: ImageViewModel

  var body: some View {
    ZStack {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
        .opacity(viewModel.isLoading ? 1 : 0)

      make(viewModel.page)
    }
  }

  @ViewBuilder
  private func make(_ image: UIImage?) -> some View {
    if let image {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }

    EmptyView()
  }

}

#Preview {
  MangaReaderView(
    viewModel: MangaReaderViewModel(
      chapterId: "97e84c86-e3cd-416d-998d-3b4c732e317d",
      restRequester: RestRequester()
    )
  )
}
