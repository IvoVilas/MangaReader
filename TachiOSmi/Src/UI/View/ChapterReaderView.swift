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

  @Environment(\.dismiss) private var dismiss

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
        .opacity(viewModel.isLoading ? 1 : 0)

      GeometryReader { geo in
        contentView()
          .opacity(viewModel.isLoading ? 0 : 1)
          .onAppear {
            Task(priority: .medium) {
              await viewModel.prepareDatasource()
            }
          }
      }

      toolBarView()
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
        .opacity(showingToolBar ? 0.9 : 0)
        .offset(y: showingToolBar ? 0 : -100)

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
    .onReceive(viewModel.closeReaderEvent) { 
      dismiss()
    }
    .onTapGesture {
      withAnimation {
        showingToolBar.toggle()
      }
    }
  }

  @ViewBuilder
  private func toolBarView() -> some View {
    VStack {
      HStack(alignment: .center, spacing: 16) {
        CustomBackAction(tintColor: .black)

        VStack(alignment: .leading) {
          Text(viewModel.mangaTitle)
            .font(.title3)
            .lineLimit(1)
            .foregroundStyle(.black)

          Text(viewModel.chapter.description)
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
        Text("\(viewModel.pagesCount)")
          .foregroundStyle(.black)
          .frame(minWidth: 24)

        PageSliderView(
          value: $viewModel.pageId,
          values: viewModel.pages
            .filter { !$0.isTransition }
            .map { $0.id }
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
            pageView(for: page, allowsZoom: true)
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
            pageView(for: page, allowsZoom: false)
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
  private func pageView(
    for page: ChapterPage,
    allowsZoom: Bool
  ) -> some View {
    switch page {
    case .page(let page):
      PageView(
        page: page,
        allowsZoom: allowsZoom,
        reloadAction: viewModel.reloadPages
      ).equatable()

    case .transition(let page):
      TransitionPageView(
        page: page,
        action: viewModel.onTransitionAction
      ).equatable()
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

    return "\(viewModel.selectedPageNumber) / \(count)"
  }


}

#Preview {
  ChapterReaderView(
    viewModel: ChapterReaderViewModel(
      source: .mangadex,
      mangaId: "c52b2ce3-7f95-469c-96b0-479524fb7a1a",
      mangaTitle: "Jujutsu Kaisen",
      chapter: ChapterModel(
        id: "5624518b-f062-49e8-84ec-e4f40e0de038",
        title: nil,
        number: nil,
        numberOfPages: 0,
        publishAt: Date(),
        isRead: false,
        lastPageRead: nil,
        downloadInfo: "5624518b-f062-49e8-84ec-e4f40e0de038"
      ),
      readingDirection: .leftToRight,
      mangaCrud: MangaCrud(),
      chapterCrud: ChapterCrud(),
      httpClient: HttpClient(),
      changedChapter: .init(),
      changedReadingDirection: .init(),
      viewMoc: PersistenceController.getViewMoc(for: .mangadex, inMemory: true)
    )
  )
}
