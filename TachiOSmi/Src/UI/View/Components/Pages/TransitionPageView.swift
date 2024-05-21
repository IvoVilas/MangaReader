//
//  TransitionPageView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 02/04/2024.
//

import SwiftUI

// MARK: Transition Page
struct TransitionPageView: View, Equatable {

  enum Action {
    case moveToNext
    case moveToPrevious
    case close
  }

  let page: TransitionPageModel
  let action: ((Action) -> Void)?

  static func == (lhs: TransitionPageView, rhs: TransitionPageView) -> Bool {
    if lhs.page.id != rhs.page.id { return false }

    switch (lhs.page, rhs.page) {
    case (.transitionToPrevious, .transitionToPrevious),
      (.transitionToNext, .transitionToNext),
      (.noNextChapter, .noNextChapter),
      (.noPreviousChapter, .noPreviousChapter):
      return true

    default:
      return false
    }
  }

  var body: some View {
    switch page {
    case .transitionToPrevious(let current, let previous):
      VStack(alignment: .leading, spacing: 48) {
        chapterTag(current, prefix: "Current")

        chapterTag(previous, prefix: "Previous")

        previousButton()
          .onTapGesture { action?(.moveToPrevious) }
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )

    case .transitionToNext(let current, let next):
      VStack(alignment: .leading, spacing: 48) {
        chapterTag(current, prefix: "Finished")

        chapterTag(next, prefix: "Next")

        nextButton()
          .onTapGesture { action?(.moveToNext) }
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )

    case .noNextChapter(let chapter):
      VStack(alignment: .leading, spacing: 48) {
        chapterTag(chapter, prefix: "Finished")

        closeButton("There is no next chapter")
          .onTapGesture { action?(.close) }
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )

    case .noPreviousChapter(let chapter):
      VStack(alignment: .leading, spacing: 48) {
        chapterTag(chapter, prefix: "Current")

        closeButton("There is no previous chapter")
          .onTapGesture { action?(.close) }
      }
      .padding(32)
      .frame(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height,
        alignment: .leading
      )
    }
  }

  @ViewBuilder
  private func chapterTag(
    _ chapter: String,
    prefix: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("\(prefix):")
        .font(.footnote)
        .foregroundStyle(.white)

      Text(chapter)
        .font(.body)
        .foregroundStyle(.white)
    }
  }

  @ViewBuilder
  private func closeButton(
    _ info: String
  ) -> some View {
    HStack(spacing: 16) {
      Image(systemName: "info.circle")
        .resizable()
        .foregroundStyle(.white)
        .frame(width: 24, height: 24)

      Text(info)
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

  @ViewBuilder
  private func nextButton() -> some View {
    HStack(spacing: 16) {
      Image(systemName: "chevron.left")
        .foregroundStyle(.white)

      Text("Go to the next chapter")
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

  @ViewBuilder
  private func previousButton() -> some View {
    HStack(spacing: 16) {
      Text("Go to the previous chapter")
        .foregroundStyle(.white)

      Image(systemName: "chevron.right")
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

}

#Preview {
  ScrollView(.horizontal) {
    HStack(spacing: 0) {
      TransitionPageView(
        page: .noNextChapter(currentChapter: "Chapter 2"),
        action: nil
      )

      TransitionPageView(
        page: .transitionToPrevious(from: "Chapter 2", to: "Chapter 1"),
        action: nil
      )

      TransitionPageView(
        page: .transitionToNext(from: "Chapter 1", to: "Chapter 2"),
        action: nil
      )

      TransitionPageView(
        page: .noPreviousChapter(currentChapter: "Chapter 1"),
        action: nil
      )
    }
  }
  .scrollTargetBehavior(.paging)
  .background(.black)
}
