//
//  MangaDetailsView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI

struct MangaDetailsView: View {

  let viewModel: MangaDetailsViewModel
  @State private var toast: Toast?

  private let backgroundColor: Color = .white
  private let foregroundColor: Color = .black

  init(
    viewModel: MangaDetailsViewModel
  ) {
    self.viewModel = viewModel

    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        ZStack(alignment: .top) {
          makeHeaderView()

          ProgressView()
            .progressViewStyle(.circular)
            .tint(foregroundColor)
            .opacity(viewModel.isLoading ? 1 : 0)
            .offset(y: 75)
        }
        Spacer().frame(height: 24)

        makeDescriptionView()

        Spacer().frame(height: 16)

        Text("\(viewModel.chapterCount) chapters")
          .font(.headline)
          .foregroundStyle(foregroundColor)
          .padding(.horizontal, 24)

        Spacer().frame(height: 24)

        LazyVStack(alignment: .leading, spacing: 24) {
          ForEach(viewModel.chapters) { chapter in
            NavigationLink(value: chapter) {
              makeChapterView(chapter)
                .onAppear {
                  Task(priority: .userInitiated) {
                    await viewModel.loadNextChapters(chapter.id)
                  }
                }
            }
          }
        }
        .padding(.horizontal, 24)
      }
    }
    .navigationBarBackButtonHidden(true)
    .scrollIndicators(.hidden)
    .ignoresSafeArea(.all, edges: .top)
    .background(backgroundColor)
    .onAppear {
      Task(priority: .medium) { await viewModel.setupData() }
    }
    .refreshable {
      Task(priority: .medium) { await viewModel.forceRefresh() }
    }
    .navigationDestination(for: ChapterModel.self) { chapter in
      ChapterReaderView(
        viewModel: viewModel.buildReaderViewModel(chapter)
      )
    }
    .toastView(toast: $toast)
    .onChange(of: viewModel.error) { _, error in
      if let error {
        toast = Toast(
          style: .error,
          message: error.localizedDescription
        )
      }
    }
    .onChange(of: viewModel.info) { _, info in
      if let info {
        toast = Toast(
          style: .success,
          message: info
        )
      }
    }
  }

  @ViewBuilder
  func makeChapterView(
    _ chapter: ChapterModel
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(chapter.description)
        .font(.subheadline)
        .lineLimit(1)
        .foregroundStyle(chapter.isRead ? .gray : foregroundColor)

      HStack(spacing: 16) {
        Text(chapter.createdAtDescription)
          .font(.caption2)
          .foregroundStyle(chapter.isRead ? .gray : foregroundColor)

        Text(chapter.lastPageReadDescription ?? "")
          .font(.caption2)
          .foregroundStyle(.gray)
          .opacity((chapter.lastPageRead ?? 0) > 0 && !chapter.isRead ? 1 : 0)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func makeHeaderView() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .top) {
        Image(uiImage: viewModel.cover.toUIImage() ?? .coverNotFound)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity)
          .frame(height: 260)
          .clipped()
          .opacity(0.4)
          .overlay {
            LinearGradient(
              gradient: Gradient(colors: [.clear, backgroundColor]),
              startPoint: .top,
              endPoint: .bottom
            )
          }

        makeInfoView()
          .offset(y: 64)
          .padding(.horizontal, 24)
      }
    }
  }

  @ViewBuilder
  private func makeInfoView() -> some View {
    VStack(alignment: .leading, spacing: 16) {
      CustomBackAction(tintColor: foregroundColor)
        .frame(width: 20, height: 20)

      HStack(spacing: 16) {
        Image(uiImage: viewModel.cover.toUIImage() ?? .coverNotFound)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 100, height: 160)
          .clipShape(RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 8) {
          Text(viewModel.title)
            .foregroundStyle(foregroundColor)
            .font(.headline)

          if let author = viewModel.authors.first {
            HStack(spacing: 4) {
              Image(systemName: "person")
                .resizable()
                .frame(width: 15, height: 15)
                .foregroundStyle(foregroundColor)

              Text(author.name)
                .foregroundStyle(foregroundColor)
                .font(.footnote)
            }
          }

          HStack(spacing: 4) {
            Image(systemName: getStatusIcon(viewModel.status))
              .resizable()
              .frame(width: 15, height: 15)
              .foregroundStyle(foregroundColor)

            Text(viewModel.status.value.localizedCapitalized)
              .foregroundStyle(foregroundColor)
              .font(.footnote)
          }

          Button {
            Task(priority: .userInitiated) {
              await viewModel.saveManga(!viewModel.isSaved)
            }
          } label: {
            HStack(spacing: 4) {
              Image(systemName: viewModel.isSaved ?  "book.closed.fill" : "book.closed")
                .foregroundStyle(viewModel.isLoading ? .gray : foregroundColor)
                .aspectRatio(1, contentMode: .fill)

              Text(viewModel.isSaved ? "In library" : "Add to library")
                .font(.caption2)
                .foregroundStyle(viewModel.isLoading ? .gray : foregroundColor)
            }
            .padding(.top, 4)
          }
          .disabled(viewModel.isLoading)
        }

        Spacer()
      }
    }
  }

  @ViewBuilder
  private func makeDescriptionView() -> some View {
    VStack(spacing: 0) {
      Text(viewModel.description ?? "")
        .font(.bold(.footnote)())
        .foregroundStyle(foregroundColor)
        .lineLimit(3)
        .opacity(viewModel.description != nil ? 1 : 0)
        .padding(.horizontal, 24)

      Spacer().frame(height: 16)

      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach(viewModel.tags) { tag in
            Text(tag.title)
              .font(.footnote)
              .lineLimit(1)
              .foregroundStyle(foregroundColor)
              .padding(.vertical, 4)
              .padding(.horizontal, 8)
              .background(
                RoundedRectangle(cornerRadius: 4)
                  .fill(backgroundColor)
                  .stroke(foregroundColor, lineWidth: 1)
              )
          }
          .padding(.vertical, 1)
        }
        .padding(.horizontal, 24)
      }
      .scrollIndicators(.hidden)
    }
  }

  private func getStatusIcon(_ status: MangaStatus) -> String {
    switch status {
    case .completed:
      return "checkmark.circle"

    case .ongoing:
      return "clock"

    case .cancelled:
      return "xmark.circle"

    case .hiatus:
      return "clock.badge.xmark"

    case .unknown:
      return "questionmark.circle"
    }
  }

}

#Preview {
  MangaDetailsView(
    viewModel: MangaDetailsView.buildPreviewViewModel()
  )
}

extension MangaDetailsView {

  static func buildPreviewViewModel(
  ) -> MangaDetailsViewModel {
    let systemDateTime = SystemDateTime()
    let mangaCrud = MangaCrud()
    let coverCrud = CoverCrud()
    let chapterCrud = ChapterCrud()
    let httpClient = HttpClient()
    let moc = PersistenceController.preview.mangaDex.viewMoc
    let manga = MangaSearchResult(
      id: "c52b2ce3-7f95-469c-96b0-479524fb7a1a",
      title: "Jujutsu Kaisen",
      cover: UIImage.jujutsuCover.jpegData(compressionQuality: 1), 
      isSaved: false
    )

    return MangaDetailsViewModel(
      source: .mangadex,
      manga: manga,
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      coverCrud: coverCrud,
      authorCrud: AuthorCrud(),
      tagCrud: TagCrud(),
      httpClient: httpClient,
      systemDateTime: systemDateTime,
      viewMoc: moc
    )
  }

}
