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
struct ChapterReaderView: View {

  @ObservedObject var viewModel: ChapterReaderViewModel
  @State private var isHorizontal = true
  @State private var toast: Toast?
  @State private var showingToolBar = false
  @State private var pageSelected: Int = 0

  var body: some View {
    ZStack(alignment: .center) {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
        .opacity(viewModel.isLoading && viewModel.pages.count == 0 ? 1 : 0)

      GeometryReader { geo in
        contentView()
          .onAppear {
            Task(priority: .medium) {
              await viewModel.fetchPages()
            }
          }
          .onTapGesture {
            withAnimation {
              showingToolBar.toggle()
            }
          }
      }

      toolBarView()
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
        .opacity(showingToolBar ? 0.9 : 0)

      pageSliderView()
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
        .opacity(showingToolBar ? 0.9 : 0)
        .offset(y: showingToolBar ? 0 : 100)

      labelView()
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
        .opacity(showingToolBar ? 0 : 1)
    }
    .statusBar(hidden: !showingToolBar)
    .navigationBarBackButtonHidden(true)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .flipsForRightToLeftLayoutDirection(true)
    .environment(\.layoutDirection, .rightToLeft)
    .background(.black)
    .toastView(toast: $toast)
    .onChange(of: pageSelected) { _, pos in
      if viewModel.pages.indices.contains(pos) {
        viewModel.pageId = viewModel.pages[pos].id
      }
    }
    .onReceive(viewModel.$pageId) { id in
      if let i = viewModel.pages.firstIndex(where: { $0.id == id }) {
        pageSelected = i
      }
    }
    .onReceive(viewModel.$error) { error in
      if let error {
        toast = Toast(
          style: .error,
          message: error.localizedDescription
        )
      }
    }
  }

  @ViewBuilder
  private func toolBarView() -> some View {
    VStack {
      HStack(alignment: .center, spacing: 16) {
        CustomBackAction(tintColor: .black)

        VStack(alignment: .leading) {
          Text("Jujutsu Kaisen")
            .font(.title3)
            .lineLimit(1)
            .foregroundStyle(.black)

          Text("Chapter 252")
            .font(.caption)
            .lineLimit(1)
            .foregroundStyle(.black)
        }

        Spacer()

        Button {
          isHorizontal.toggle()
        } label: {
          Image(systemName: isHorizontal ? "arrow.left.arrow.right" : "arrow.up.arrow.down")
            .tint(.black)
        }
      }
      .padding(.bottom, 16)
      .padding(.horizontal, 16)
      .background(.white)

      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  private func pageSliderView() -> some View {
    VStack {
      Spacer()

      HStack(spacing: 16) {
        Text("\(viewModel.pagesCount)")
          .frame(minWidth: 24)

        PageSliderView(
          value: $pageSelected,
          numberOfValues: viewModel.pagesCount,
          onChange: viewModel.moveToPage
        )
        .frame(height: 24)
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)

        Text("\(pageSelected + 1)")
          .frame(minWidth: 24)
      }
      .padding(16)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 28))
      .padding(.horizontal, 16)
    }
  }

  @ViewBuilder
  private func contentView() -> some View {
    if isHorizontal {
      ScrollView(.horizontal) {
        LazyHStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            PageView(
              page: page,
              reloadAction: viewModel.reloadPages
            )
            .equatable()
            .flipsForRightToLeftLayoutDirection(true)
            .environment(\.layoutDirection, .rightToLeft)
            .onAppear {
              Task(priority: .medium) {
                await viewModel.loadNextIfNeeded(page.id)
              }
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: $viewModel.pageId)
    } else {
      ScrollView() {
        LazyVStack(spacing: 0) {
          ForEach(viewModel.pages) { page in
            PageView(
              page: page,
              reloadAction: viewModel.reloadPages
            )
            .equatable()
            .flipsForRightToLeftLayoutDirection(true)
            .environment(\.layoutDirection, .rightToLeft)
            .onAppear {
              Task(priority: .medium) {
                await viewModel.loadNextIfNeeded(page.id)
              }
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollIndicators(.hidden)
      .scrollPosition(id: $viewModel.pageId)
    }
  }

  @ViewBuilder
  private func labelView() -> some View {
    VStack {
      Spacer()

      Text(pageLabel())
        .lineLimit(1)
        .font(.subheadline.bold())
        .foregroundStyle(.white)
    }
  }

  private func pageLabel() -> String {
    let count = viewModel.pagesCount

    if count == 0 { return "0 / 0" }

    return "\(pageSelected + 1) / \(count)"
  }


}

private struct PageView: View, Equatable {

  let page: PageModel
  let reloadAction: ((PageModel) async -> Void)?

  var body: some View {
    switch page {
    case .remote(_, _, let data):
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
          Task(priority: .userInitiated) { await reloadAction?(page) }
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

  static func == (lhs: PageView, rhs: PageView) -> Bool {
    if lhs.page.id != rhs.page.id { return false }

    switch (lhs.page, rhs.page) {
    case (.loading, .loading), (.remote, .remote), (.notFound, .notFound):
      return true

    default:
      return false
    }
  }

}

#Preview {
  ChapterReaderView(
    viewModel: ChapterReaderViewModel(
      datasource: PagesDatasource(
        chapter: ChapterModel(
          id: "e7c4d0c9-cec9-4116-aba1-178b2a5d4cc3",
          title: nil,
          number: nil,
          numberOfPages: 25,
          publishAt: Date(),
          isRead: false,
          downloadInfo: "e7c4d0c9-cec9-4116-aba1-178b2a5d4cc3"
        ),
        delegate: MangadexPagesDelegate(
          httpClient: HttpClient()
        )
      )
    )
  )
}
