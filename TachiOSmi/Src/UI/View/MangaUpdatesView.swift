//
//  MangaUpdatesView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 22/04/2024.
//

import SwiftUI
import CoreData

struct MangaUpdatesView: View {

  @Environment(\.colorScheme) private var scheme
  @Environment(\.refreshLibraryUseCase) private var refreshUseCase

  @StateObject var viewModel: MangaUpdatesViewModel
  @State var isLoading = false

  init(
    coverCrud: CoverCrud = AppEnv.env.coverCrud,
    chapterCurd: ChapterCrud = AppEnv.env.chapterCrud,
    formatter: Formatter = AppEnv.env.formatter,
    systemDateTime: SystemDateTimeType = AppEnv.env.systemDateTime,
    viewMoc: NSManagedObjectContext = PersistenceController.shared.container.viewContext
  ) {
    _viewModel = StateObject(
      wrappedValue: MangaUpdatesViewModel(
        provider: MangaUpdatesProvider(
          coverCrud: coverCrud,
          chapterCrud: chapterCurd,
          formatter: formatter,
          systemDateTime: systemDateTime,
          viewMoc: viewMoc
        )
      )
    )
  }

  var body: some View {
    VStack(alignment: .center) {
      ZStack {
        HStack {
          Text("Updates")
            .foregroundStyle(scheme.foregroundColor)
            .font(.title)

          Spacer()

          Button { refreshLibrary() } label: {
            Image(systemName: "arrow.clockwise")
              .foregroundStyle(scheme.foregroundColor)
          }
        }

        ProgressView()
          .controlSize(.regular)
          .progressViewStyle(.circular)
          .opacity(isLoading ? 1 : 0)
          .offset(y: isLoading ? 0 : -75)
          .animation(.easeInOut, value: isLoading)
      }

      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach($viewModel.logs) { log in
            MangaUpdateLogDateView(
              logs: log,
              foregroundColor: scheme.foregroundColor,
              getNavigator: viewModel.getNavigator
            )
            .onAppear {
              if log.id == viewModel.logs.last?.id {
                viewModel.loadMoreLogs()
              }
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .background(scheme.backgroundColor)
  }

  private func refreshLibrary() {
    Task(priority: .userInitiated) {
      await MainActor.run { isLoading = true }

      await refreshUseCase.refresh()

      await MainActor.run { isLoading = false }
    }
  }

}

private struct MangaUpdateLogDateView: View {

  @Binding var logs: MangaUpdatesProvider.MangaUpdatesLogDate

  let foregroundColor: Color
  let getNavigator: (MangaUpdatesProvider.MangaUpdateLogModel) -> MangaReaderNavigator

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(logs.dateDescription)
        .font(.subheadline)
        .lineLimit(1)
        .foregroundStyle(foregroundColor)

      VStack(spacing: 8) {
        ForEach(logs.logs) { log in
          NavigationLink(value: getNavigator(log)) {
            logView(log)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func logView(
    _ log: MangaUpdatesProvider.MangaUpdateLogModel
  ) -> some View {
    HStack(spacing: 16) {
      Image(uiImage: log.manga.cover.toUIImage() ?? .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 8) {
        Text(log.manga.title)
          .font(.subheadline)
          .lineLimit(1)
          .foregroundStyle(log.chapter.isRead ? .gray : foregroundColor)

        HStack(spacing: 2) {
          Text(log.chapterTitle)
            .font(.caption2)
            .foregroundStyle(log.chapter.isRead ? .gray : foregroundColor)

          Text("\u{2022}")
            .font(.caption)
            .foregroundStyle(foregroundColor)
            .opacity((log.chapter.lastPageRead ?? 0) > 0 && !log.chapter.isRead ? 1 : 0)

          Text(log.lastPageReadDescription ?? "")
            .font(.caption2)
            .foregroundStyle(.gray)
            .opacity((log.chapter.lastPageRead ?? 0) > 0 && !log.chapter.isRead ? 1 : 0)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

}

#Preview {
  MangaUpdatesView(
    viewMoc: PersistenceController.preview.container.viewContext
  )
}
