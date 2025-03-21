//
//  MangaDetailsView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 04/04/2024.
//

import SwiftUI
import CoreData

struct MangaDetailsView: View {

  @Environment(\.router) private var router
  @Environment(\.colorScheme) private var scheme

  @StateObject var viewModel: MangaDetailsViewModel

  @State private var toast: Toast?
  @State private var isDescriptionExpanded = false
  @State private var offset = CGPoint.zero
  @State private var selectedItem: ChapterModel?

  init(
    manga: MangaSearchResult,
    mangaCrud: MangaCrud = AppEnv.env.mangaCrud,
    chapterCrud: ChapterCrud = AppEnv.env.chapterCrud,
    coverCrud: CoverCrud = AppEnv.env.coverCrud,
    authorCrud: AuthorCrud = AppEnv.env.authorCrud,
    tagCrud: TagCrud = AppEnv.env.tagCrud,
    httpClient: HttpClientType = AppEnv.env.httpClient,
    systemDateTime: SystemDateTimeType = AppEnv.env.systemDateTime,
    appOptionsStore: AppOptionsStore = AppEnv.env.appOptionsStore,
    container: NSPersistentContainer = PersistenceController.shared.container
  ) {
    _viewModel = StateObject(
      wrappedValue: MangaDetailsViewModel(
        manga: manga,
        mangaCrud: mangaCrud,
        chapterCrud: chapterCrud,
        coverCrud: coverCrud,
        authorCrud: authorCrud,
        tagCrud: tagCrud,
        httpClient: httpClient,
        systemDateTime: systemDateTime,
        appOptionsStore: appOptionsStore,
        container: container
      )
    )
  }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      PositionObservingScrollView(
        offset: $offset
      ) {
        ZStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
              ZStack(alignment: .bottom) {
                backgroundView()
                  .offset(y: -max(offset.y, 0))

                infoView()
                  .padding(.horizontal, 24)
              }

              navbarView()
                .padding(.horizontal, 24)
                .offset(y: 64)
            }

            Spacer().frame(height: 16)

            ExpandableTextView(
              text: viewModel.manga.description ?? "",
              lineLimit: 3,
              font: .footnote,
              foregroundColor: scheme.foregroundColor,
              backgroundColor: scheme.backgroundColor,
              isExpanded: $isDescriptionExpanded
            )
            .id(viewModel.manga.description ?? "")
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            tagsView()

            Spacer().frame(height: 16)

            chaptersCountView()
              .padding(.horizontal, 24)

            chaptersView()
          }

          ProgressView()
            .controlSize(.regular)
            .progressViewStyle(.circular)
            .tint(scheme.foregroundColor)
            .opacity(viewModel.isLoading ? 1 : 0)
            .offset(y: viewModel.isLoading ? 75 : -100)
            .animation(.easeInOut, value: viewModel.isLoading)
        }
      }
      .refreshable { await viewModel.forceRefresh() }
      .ignoresSafeArea(.all, edges: .top)

      if viewModel.showPlayButton {
        PlayButton(
          title: $viewModel.playButtonTitle,
          offset: .constant(offset.y),
          scheme: scheme
        ) {
          guard let navigatior = viewModel.getResumeNavigation() else {
            return
          }
          
          router.navigate(using: navigatior)
        }
        .offset(x: viewModel.isSelectionOn ? 200 : 0)
        .opacity(viewModel.isSelectionOn ? 0 : 1)
        .animation(.bouncy(duration: 0.3), value: viewModel.isSelectionOn)
        .padding(.trailing, 24)
      }

      toolBar()
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(scheme.terciaryColor)
        .offset(y: viewModel.isSelectionOn ? 0 : 100)
        .opacity(viewModel.isSelectionOn ? 1 : 0)
        .shadow(
          color: .black.opacity(viewModel.isSelectionOn ? 0.2 : 0),
          radius: 10
        )
        .animation(.bouncy(duration: 0.3), value: viewModel.isSelectionOn)
        .animation(.bouncy(duration: 0.3), value: viewModel.toolbarActions)

    }
    .navigationBarBackButtonHidden(true)
    .background(scheme.backgroundColor)
    .task { await viewModel.setupData() }
    .toastView(toast: $toast)
    .onReceive(viewModel.$error) { error in
      if let error {
        toast = Toast(
          style: .error,
          message: error.localizedDescription
        )
      }
    }
    .onReceive(viewModel.$info) { info in
      if let info {
        toast = Toast(
          style: .success,
          message: info
        )
      }
    }
  }

  @ViewBuilder
  private func backgroundView() -> some View {
    Image(uiImage: viewModel.manga.cover.toUIImage() ?? .coverNotFound)
      .resizable()
      .scaledToFill()
      .frame(maxWidth: .infinity)
      .frame(height: 260)
      .clipped()
      .opacity(0.4)
      .overlay {
        LinearGradient(
          gradient: Gradient(colors: [.clear, scheme.backgroundColor]),
          startPoint: .top,
          endPoint: .bottom
        )
      }
  }

  @ViewBuilder
  private func navbarView() -> some View {
    CustomBackAction(tintColor: scheme.foregroundColor)
      .frame(width: 20, height: 20)
  }

  @ViewBuilder
  private func infoView() -> some View {
    HStack(spacing: 16) {
      Image(uiImage: viewModel.manga.cover.toUIImage() ?? .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 100, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 8) {
        Text(viewModel.manga.title)
          .foregroundStyle(scheme.foregroundColor)
          .lineLimit(3)
          .font(.headline)

        HStack(spacing: 4) {
          Image("person")
            .resizable()
            .scaledToFit()
            .frame(width: 18)
            .foregroundStyle(scheme.foregroundColor)

          Text(viewModel.manga.authors.first?.name ?? "")
            .foregroundStyle(scheme.foregroundColor)
            .font(.footnote)
        }
        .frame(height: viewModel.manga.authors.first == nil ? 0 : nil)
        .opacity(viewModel.manga.authors.first == nil ? 0 : 1)

        HStack(spacing: 4) {
          Image(getStatusIcon(viewModel.manga.status))
            .resizable()
            .scaledToFit()
            .frame(width: 18)
            .foregroundStyle(scheme.foregroundColor)

          Text(viewModel.manga.status.value.localizedCapitalized)
            .foregroundStyle(scheme.foregroundColor)
            .font(.footnote)

          Text("\u{2022}")
            .foregroundStyle(scheme.foregroundColor)
            .font(.footnote)

          Text(viewModel.manga.source.name)
            .foregroundStyle(scheme.foregroundColor)
            .font(.footnote)
        }

        Button {
          Task(priority: .userInitiated) {
            await viewModel.saveManga(!viewModel.manga.isSaved)
          }
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "book.closed")
              .aspectRatio(1, contentMode: .fill)
              .symbolVariant(viewModel.manga.isSaved ? .fill : .none)
              .symbolEffect(.bounce, value: viewModel.manga.isSaved)
              .foregroundStyle(viewModel.isLoading ? .gray : scheme.foregroundColor)

            Text(viewModel.manga.isSaved ? "In library" : "Add to library")
              .font(.caption2)
              .foregroundStyle(viewModel.isLoading ? .gray : scheme.foregroundColor)
          }
          .padding(.top, 4)
        }
        .disabled(viewModel.isLoading)
      }

      Spacer()
    }
  }

  @ViewBuilder
  private func tagsView() -> some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(viewModel.manga.tags) { tag in
          Text(tag.title)
            .font(.footnote)
            .lineLimit(1)
            .foregroundStyle(scheme.foregroundColor)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(scheme.backgroundColor)
                .stroke(scheme.foregroundColor, lineWidth: 1)
            )
        }
        .padding(.vertical, 1)
      }
      .padding(.horizontal, 24)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private func chaptersCountView() -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(viewModel.chaptersCount) chapters")
        .font(.headline)
        .foregroundStyle(scheme.foregroundColor)

      Text("Missing \(viewModel.missingChaptersCount) chapters")
        .font(.caption)
        .foregroundStyle(
          viewModel.isMissingChaptersRead ? .gray : .red
        )
        .frame(height: viewModel.missingChaptersCount > 0 ? nil : 0)
        .opacity(viewModel.missingChaptersCount > 0 ? 1 : 0)
    }
  }

  @ViewBuilder
  private func toolBar() -> some View {
    HStack(spacing: 0) {
      Spacer()

      ForEach(viewModel.toolbarActions) { action in
        Button { viewModel.onToolbarAction(action) } label : {
          action.icon.image()
            .resizable()
            .scaledToFit()
            .frame(width: 24)
            .foregroundStyle(scheme.foregroundColor)
        }

        Spacer()
      }
    }
  }

  @ViewBuilder
  private func chaptersView() -> some View {
    LazyVStack(alignment: .leading, spacing: 0) {
      ForEach(viewModel.chapters) { chapter in
        switch chapter {
        case .chapter(let chapter):
          Button { } label: {
            ChapterEntryView(
              chapter: chapter,
              scheme: scheme
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
              viewModel.selectedChapters.contains(chapter.id) ? .teal.opacity(0.2) : scheme.backgroundColor
            )
            .animation(.easeInOut, value: viewModel.selectedChapters.contains(chapter.id))
            .onTapGesture {
              if viewModel.isSelectionOn {
                viewModel.selectItem(chapter.id)
              } else {
                router.navigate(
                  using: viewModel.getNavigator(chapter)
                )
              }
            }
            .onLongPressGesture(minimumDuration: 0.3) {
              if viewModel.isSelectionOn {
                viewModel.selectItem(chapter.id)
              } else {
                viewModel.isSelectionOn = true
                viewModel.selectItem(chapter.id)
              }
            }
          }

        case .missing(let missing):
          MissingChapterEntryView(missing: missing)
        }
      }
    }
  }

  private func getStatusIcon(_ status: MangaStatus) -> String {
    switch status {
    case .completed:
      return "done_all"

    case .ongoing:
      return "ongoing"

    case .cancelled:
      return "cancelled"

    case .hiatus:
      return "hiatus"

    case .unknown:
      return "unknown"
    }
  }

}

private struct PlayButton: View {

  @Binding var title: String
  @Binding var offset: CGFloat
  @State var expandButton: Bool = true

  let scheme: ColorScheme
  let action: () -> Void

  var body: some View {
    Button { action() } label: {
      HStack(spacing: 12) {
        Image(systemName: "play.fill")
          .resizable()
          .scaledToFit()
          .foregroundStyle(scheme.foregroundColor)
          .frame(width: 16)
          .padding(.vertical, 24)
          .padding(.leading, 24)
          .padding(.trailing, expandButton ? 0 : 24)

        if expandButton {
          Text(title)
            .font(.callout)
            .lineLimit(1)
            .foregroundStyle(scheme.foregroundColor)
            .padding(.trailing, 24)
            .transition(.scale)
        }
      }
    }
    .background(scheme.terciaryColor)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .onChange(of: offset) { oldValue, value in
      withAnimation {
        expandButton = value >= oldValue || value >= 0
      }
    }
  }

}

#Preview {
  NavigationStack {
    MangaDetailsView(
      manga: MangaSearchResult(
        id: "1",
        title: "Jujutsu Kaisen",
        cover: UIImage.jujutsuCover.jpegData(compressionQuality: 1),
        source: .unknown
      ),
      appOptionsStore: AppOptionsStore.inMemory(),
      container: PersistenceController.preview.container
    )
  }
}

#Preview {

  PlayButton(
    title: .constant("Resume"),
    offset: .constant(0),
    scheme: .light
  ) { }

}
