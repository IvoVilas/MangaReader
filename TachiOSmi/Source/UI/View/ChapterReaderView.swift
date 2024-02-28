//
//  ChapterReaderView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import SwiftUI
import Combine

struct ChapterReaderView: View {

  @ObservedObject var viewModel: MangaReaderViewModel
  @State private var isHorizontal = true
  @State private var toast: Toast?

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
    // This flips the view horizontal when layout direction is right to left
    // (view arrives flipped from the datasource)
    .flipsForRightToLeftLayoutDirection(true)
    // This changes layout direction so that HStack grows from right to left
    .environment(\.layoutDirection, .rightToLeft)
    .background(.black)
    .toastView(toast: $toast)
    .onReceive(viewModel.$error) { error in
      if let error {
        toast = Toast(
          style: .error,
          message: error.localizedDescription
        )
      }
    }
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
            makePage(page: page, proxy: proxy)
              .onAppear {
                Task(priority: .background) {
                  await viewModel.loadNextIfNeeded(page.id)
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
            makePage(page: page, proxy: proxy)
              .onAppear {
                Task(priority: .background) {
                  await viewModel.loadNextIfNeeded(page.id)
                }
              }
          }
        }
      }
    }
  }

  @ViewBuilder
  private func makePage(
    page: PageModel,
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
        ZStack(alignment: .bottom) {
          Image(uiImage: .coverNotFound)
            .resizable()
            .aspectRatio(contentMode: .fit)

          Button {
            Task(priority: .userInitiated) {
              await viewModel.reloadPages(startingAt: page)
            }
          } label: {
            HStack(alignment: .center, spacing: 8) {
              Text("Retry")
                .font(.body)
                .foregroundStyle(.white)

              Image(systemName: "arrow.triangle.2.circlepath.icloud")
                .tint(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
          }
        }
        .frame(width: proxy.size.width)
      }
  }

}

#Preview {
  ChapterReaderView(
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
