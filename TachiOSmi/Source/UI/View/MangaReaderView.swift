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
        LazyHStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            makePage(page, proxy: proxy)
              .task(priority: .background) {
                if page.id == viewModel.pages.last?.id {
                  await viewModel.loadNext()
                }
              }
          }
        }
      }
      .scrollTargetBehavior(.paging)
    } else {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            makePage(page, proxy: proxy)
              .task(priority: .background) {
                if page.id == viewModel.pages.last?.id {
                  await viewModel.loadNext()
                }
              }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func makePage(
    _ page: PageModel,
    proxy: GeometryProxy
  ) -> some View {
    switch page {
    case .remote(_, let data):
      Image(uiImage: UIImage(data: data) ?? .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: proxy.size.width)

    case .loading:
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
        .frame(width: proxy.size.width, height: proxy.size.height)

    case .notFound:
      Image(uiImage: .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: proxy.size.width)
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
