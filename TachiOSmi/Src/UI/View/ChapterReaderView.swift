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
  @State private var toast: Toast?
  @State private var showingToolBar = false

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
          Task(priority: .medium) {
            await viewModel.changeReadingDirection(
              to: viewModel.readingDirection.toggle()
            )
          }
        } label: {
          Image(
            systemName: viewModel.readingDirection.isHorizontal ?
            "arrow.left.arrow.right" : "arrow.up.arrow.down"
          )
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
        Text("\(viewModel.chapterPages.count)")
          .foregroundStyle(.black)
          .frame(minWidth: 24)

        PageSliderView(
          value: $viewModel.pageId,
          values: viewModel.chapterPages.map { $0.id },
          onChanged: { _ in }
        )
        .frame(height: 24)
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)

        Text("\(viewModel.selectedPageNumber)")
          .foregroundStyle(.black)
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
    if viewModel.readingDirection.isHorizontal {
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
                await viewModel.onPageTask(page.id)
              }
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .flipsForRightToLeftLayoutDirection(true)
            .environment(\.layoutDirection, .rightToLeft)
            .onAppear {
              Task(priority: .medium) {
                await viewModel.onPageTask(page.id)
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
    let count = viewModel.chapterPages.count

    if count == 0 { return "0 / 0" }

    return "\(viewModel.selectedPageNumber) / \(count)"
  }


}

private struct PageView: View, Equatable {

  let page: ChapterPage
  let reloadAction: ((PageModel) async -> Void)?

  var body: some View {
    switch page {
    case .page(let page):
      makeChapterPage(page)

    case .transition(let page):
      makeTransitionPage(page)
    }
  }

  @ViewBuilder
  private func makeChapterPage(_ page: PageModel) -> some View {
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

  @ViewBuilder
  private func makeTransitionPage(_ page: TransitionPageModel) -> some View {
    switch page {
    case .transitionToPrevious(let from, let to):
      Text("Move from \(from) to \(to) (previous)")
        .foregroundStyle(.white)
        .frame(
          width: UIScreen.main.bounds.width,
          height: UIScreen.main.bounds.height
        )

    case .transitionToNext(let from, let to):
      Text("Move from \(from) to \(to) (next)")
        .foregroundStyle(.white)
        .frame(
          width: UIScreen.main.bounds.width,
          height: UIScreen.main.bounds.height
        )

    case .noNextChapter:
      Text("There is no next chapter")
        .foregroundStyle(.white)
        .frame(
          width: UIScreen.main.bounds.width,
          height: UIScreen.main.bounds.height
        )

    case .noPreviousChapter:
      Text("There is no previous chapter")
        .foregroundStyle(.white)
        .frame(
          width: UIScreen.main.bounds.width,
          height: UIScreen.main.bounds.height
        )
    }
  }

  static func == (lhs: PageView, rhs: PageView) -> Bool {
    if lhs.page.id != rhs.page.id { return false }

    switch (lhs.page, rhs.page) {
    case (.page(let left), .page(let right)):
      return compare(lhs: left, rhs: right)

    case (.transition(let left), .transition(let right)):
      return left.id == right.id

    default:
      return false
    }
  }

  private static func compare(lhs: PageModel, rhs: PageModel) -> Bool {
    switch (lhs, rhs) {
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
      readingDirection: .leftToRight,
      source: .mangadex,
      mangaId: "c52b2ce3-7f95-469c-96b0-479524fb7a1a",
      chapter: ChapterModel(
        id: "5624518b-f062-49e8-84ec-e4f40e0de038",
        title: nil,
        number: nil,
        numberOfPages: 0,
        publishAt: Date(),
        isRead: false,
        downloadInfo: "5624518b-f062-49e8-84ec-e4f40e0de038"
      ),
      chapters: [],
      mangaCrud: MangaCrud(),
      httpClient: HttpClient(),
      viewMoc: PersistenceController.getViewMoc(for: .mangadex, inMemory: true)
    )
  )
}
