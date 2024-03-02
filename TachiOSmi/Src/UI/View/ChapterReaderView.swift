//
//  ChapterReaderView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import SwiftUI
import Combine

// LazyStacks does not work well with layoutDirection rightToLeft
// To make it work I had to also enable flipsForRightToLeftLayoutDirection
// Twist, pages were flipped, so I also need to flip every single page
// Basically, I do a double flip to make it work
struct ChapterReaderView<Source: SourceType>: View {

  @ObservedObject var viewModel: ChapterReaderViewModel<Source>
  @State private var isHorizontal = true
  @State private var toast: Toast?

  var body: some View {
    ZStack(alignment: .center) {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
        .opacity(viewModel.pages.count == 0 ? 1 : 0)
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)

      makeScrollView()
        .onAppear {
          Task(priority: .medium) {
            await viewModel.fetchPages()
          }
        }
    }
    .ignoresSafeArea()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .flipsForRightToLeftLayoutDirection(true)
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
  private func makeScrollView() -> some View {
    if isHorizontal {
      ScrollView(.horizontal) {
        LazyHStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            makePage(page: page)
              .flipsForRightToLeftLayoutDirection(true)
              .environment(\.layoutDirection, .rightToLeft)
              .onAppear {
                Task(priority: .medium) {
                  await viewModel.loadNextIfNeeded(page.id)
                }
              }
          }
        }
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.paging)
    } else {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            makePage(page: page)
              .flipsForRightToLeftLayoutDirection(true)
              .environment(\.layoutDirection, .rightToLeft)
              .onAppear {
                Task(priority: .medium) {
                  await viewModel.loadNextIfNeeded(page.id)
                }
              }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  @ViewBuilder
  private func makePage(
    page: PageModel
  ) -> some View {
    switch page {
    case .remote(_, let data):
      Image(uiImage: UIImage(data: data) ?? .imageNotFound)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: UIScreen.main.bounds.width)

    case .loading:
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
        .frame(
          width: UIScreen.main.bounds.width,
          height: UIScreen.main.bounds.height
        )

    case .notFound:
      ZStack(alignment: .bottom) {
        Image(uiImage: .imageNotFound)
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
      .frame(width: UIScreen.main.bounds.width)
    }
  }

}

#Preview {
  ChapterReaderView<MangadexMangaSource>(
    viewModel: ChapterReaderViewModel(
      datasource: PagesDatasource(
        chapter: ChapterModel(
          id: "556c3feb-8c62-43de-b872-4657730d31a1",
          title: nil,
          number: nil,
          numberOfPages: 25,
          publishAt: Date(),
          urlInfo: "556c3feb-8c62-43de-b872-4657730d31a1"
        ),
        delegate: MangadexPagesDelegate(
          httpClient: HttpClient()
        )
      )
    )
  )
}
