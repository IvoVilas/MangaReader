//
//  MangaUpdatesView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 22/04/2024.
//

import SwiftUI

struct MangaUpdatesView: View {

  @Environment(\.colorScheme) private var scheme

  @ObservedObject var viewModel: MangaUpdatesViewModel

  var body: some View {
    VStack(alignment: .center) {
      HStack {
        Text("Updates")
          .foregroundStyle(scheme.foregroundColor)
          .font(.title)

        Spacer()

        Button {} label: {
          Image(systemName: "arrow.clockwise")
            .foregroundStyle(scheme.foregroundColor)
        }
      }

      ScrollView {
        VStack(spacing: 16) {
          ForEach(viewModel.logs) { log in
            MangaUpdateLogDateView(
              logs: log,
              foregroundColor: scheme.foregroundColor
            )
            .onAppear {
              if log.id == viewModel.logs.last?.id {
                Task(priority: .userInitiated) {
                  await viewModel.fetchNextLogs()
                }
              }
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .background(scheme.backgroundColor)
    .onAppear {
      Task(priority: .high) {
        await viewModel.fetchNextLogs()
      }
    }
  }

}

private struct MangaUpdateLogDateView: View {

  @State var logs: MangaUpdatesViewModel.MangaUpdatesLogDate

  let foregroundColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(logs.dateDescription)
        .font(.subheadline)
        .lineLimit(1)
        .foregroundStyle(foregroundColor)

      VStack(spacing: 8) {
        ForEach(logs.logs) { log in
          MangaUpdateLogView(
            log: log,
            foregroundColor: foregroundColor
          )
        }
      }
    }
  }

}

private struct MangaUpdateLogView: View {

  @State var log: MangaUpdateLogModel

  let foregroundColor: Color

  var body: some View {
    HStack(spacing: 16) {
      Image(uiImage: log.mangaCover.toUIImage() ?? .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 8) {
        Text(log.mangaTitle)
          .font(.subheadline)
          .lineLimit(1)
          .foregroundStyle(log.isRead ? .gray : foregroundColor)

        HStack(spacing: 16) {
          Text(log.chapterTitle)
            .font(.caption2)
            .foregroundStyle(log.isRead ? .gray : foregroundColor)

          Text(log.lastPageReadDescription ?? "")
            .font(.caption2)
            .foregroundStyle(.gray)
            .opacity((log.lastPageRead ?? 0) > 0 && !log.isRead ? 1 : 0)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

}

#Preview {
  MangaUpdatesView(
    viewModel: MangaUpdatesViewModel(
      coverCrud: CoverCrud(),
      chapterCrud: ChapterCrud(),
      systemDateTime: SystemDateTime(),
      viewMoc: PersistenceController.preview.container.viewContext
    )
  )
}
