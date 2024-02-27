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
  @State private var isHorizontal = true

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .center) {
        ProgressView()
          .progressViewStyle(.circular)
          .tint(.white)
          .opacity(viewModel.pages.count == 0 ? 1 : 0)

        makeScrollView(geo)
          .task(priority: .background) { await viewModel.fetchPages() }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    .background(.black)
    .environment(\.layoutDirection, .rightToLeft)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isHorizontal.toggle()
        } label: {
          Image(systemName: isHorizontal ? "arrow.left" : "arrow.down")
            .tint(.white)
        }
      }
    }
  }

  @ViewBuilder
  private func makeScrollView(
    _ proxy: GeometryProxy
  ) -> some View {
    if isHorizontal {
      ScrollView(.horizontal) {
        HStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            makePage(page)
              .frame(width: proxy.size.width)
          }
        }
      }
      .scrollTargetBehavior(.paging)
    } else {
      ScrollView {
        VStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            makePage(page)
              .frame(width: proxy.size.width)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func makePage(
    _ page: PageModel
  ) -> some View {
    switch page {
    case .remote(_, let data):
      Image(uiImage: UIImage(data: data) ?? .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fit)

    case .loading:
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)

    case .notFound:
      Image(uiImage: .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }

}

#Preview {
  MangaReaderView(
    viewModel: MangaReaderViewModel(
      datasource: ChapterPagesDatasource(
        chapter: ChapterModel(
          id: "556c3feb-8c62-43de-b872-4657730d31a1",
          title: "Blood and Oil ②",
          number: 203,
          numberOfPages: 21,
          publishAt: SystemDateTime().builder.makeDate(day: 6, month: 11, year: 2022)
        ),
        httpClient: HttpClient()
      )
    )
  )
}
