//
//  ChapterPageView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 27/03/2024.
//

import Foundation
import SwiftUI

struct ChapterPageView: View, Equatable {

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
    case .transitionToPrevious(let current, let previous):
      VStack(alignment: .leading, spacing: 48) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Previous:")
            .font(.footnote)
            .foregroundStyle(.white)

          Text(previous)
            .font(.body)
            .foregroundStyle(.white)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Current:")
            .font(.footnote)
            .foregroundStyle(.white)

          Text(current)
            .font(.body)
            .foregroundStyle(.white)
        }
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )

    case .transitionToNext(let current, let next):
      VStack(alignment: .leading, spacing: 48) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Finished:")
            .font(.footnote)
            .foregroundStyle(.white)

          Text(current)
            .font(.body)
            .foregroundStyle(.white)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Next:")
            .font(.footnote)
            .foregroundStyle(.white)

          Text(next)
            .font(.body)
            .foregroundStyle(.white)
        }
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )

    case .noNextChapter(let chapter):
      VStack(alignment: .leading, spacing: 48) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Finished:")
            .font(.footnote)
            .foregroundStyle(.white)

          Text(chapter)
            .font(.body)
            .foregroundStyle(.white)
        }

        HStack(spacing: 16) {
          Image(systemName: "info.circle")
            .resizable()
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)

          Text("There is no next chapter")
            .foregroundStyle(.white)
        }
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(.black)
            .stroke(.white, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .center)
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )

    case .noPreviousChapter(let chapter):
      VStack(alignment: .leading, spacing: 48) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Finished:")
            .font(.footnote)
            .foregroundStyle(.white)

          Text(chapter)
            .font(.body)
            .foregroundStyle(.white)
        }

        HStack(spacing: 16) {
          Image(systemName: "info.circle")
            .resizable()
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)

          Text("There is no previous chapter")
            .foregroundStyle(.white)
        }
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(.black)
            .stroke(.white, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .center)
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )
    }
  }

  static func == (lhs: ChapterPageView, rhs: ChapterPageView) -> Bool {
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
  ScrollView(.horizontal) {
    HStack(spacing: 0) {
      ChapterPageView(
        page: .transition(.transitionToPrevious(from: "Chapter 2", to: "Chapter 1"))
      ) { _ in }

      ChapterPageView(
        page: .transition(.noNextChapter(currentChapter: "Chapter 2"))
      ) { _ in }

      ChapterPageView(
        page: .transition(.transitionToPrevious(from: "Chapter 2", to: "Chapter 1"))
      ) { _ in }

      ChapterPageView(
        page: .transition(.transitionToNext(from: "Chapter 1", to: "Chapter 2"))
      ) { _ in }

      ChapterPageView(
        page: .transition(.noPreviousChapter(currentChapter: "Chapter 1"))
      ) { _ in }
    }
  }
  .scrollTargetBehavior(.paging)
  .background(.black)
}
