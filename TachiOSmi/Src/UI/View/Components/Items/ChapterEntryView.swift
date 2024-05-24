//
//  ChapterEntryView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 22/05/2024.
//

import SwiftUI

struct ChapterEntryView: View {

  var chapter: ChapterModel
  var scheme: ColorScheme

  var body: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        Text(chapter.description)
          .font(.subheadline)
          .lineLimit(1)
          .foregroundStyle(chapter.isRead ? .gray : scheme.foregroundColor)

        HStack(spacing: 2) {
          Text(chapter.createdAtDescription)
            .font(.caption2)
            .foregroundStyle(chapter.isRead ? .gray : scheme.foregroundColor)

          Text("\u{2022}")
            .font(.caption)
            .foregroundStyle(.black)
            .opacity((chapter.lastPageRead ?? 0) > 0 && !chapter.isRead ? 1 : 0)

          Text(chapter.lastPageReadDescription ?? "")
            .font(.caption2)
            .foregroundStyle(.gray)
            .opacity((chapter.lastPageRead ?? 0) > 0 && !chapter.isRead ? 1 : 0)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

}

struct MissingChapterEntryView: View {

  @State var missing: MissingChaptersModel

  var body: some View {
    HStack(spacing: 16) {
      Spacer()
        .frame(height: 1)
        .background(.gray)

      Text("Missing \(missing.count) \(missing.count == 1 ? "chapter" : "chapters")")
        .font(.caption2)
        .lineLimit(1)
        .foregroundStyle(.gray)
        .layoutPriority(1)

      Spacer()
        .frame(height: 1)
        .background(.gray)
    }
  }

}

private struct Preview_Content: View {

  @State var chapter: ChapterModel

  var body: some View {
    VStack {
      ChapterEntryView(
        chapter: chapter,
        scheme: .light
      )

      MissingChapterEntryView(
        missing: MissingChaptersModel(
          number: 166, count: 10
        )
      )
    }
  }

}

#Preview {
  Preview_Content(
    chapter: ChapterModel(
      id: "5624518b-f062-49e8-84ec-e4f40e0de038",
      title: nil,
      number: 165,
      numberOfPages: 0,
      publishAt: Date(),
      isRead: false,
      lastPageRead: nil,
      downloadInfo: "5624518b-f062-49e8-84ec-e4f40e0de038"
    )
  )
}
