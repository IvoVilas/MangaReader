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
  @State private var descipitionExpanded = false

  private let backgroundColor: Color = .white
  private let foregroundColor: Color = .black

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

        makeDescriptionView(
          description: viewModel.manga.description
        )

        Spacer().frame(height: 16)

        VStack(alignment: .leading, spacing: 4) {
          Text("\(viewModel.chaptersCount) chapters")
            .font(.headline)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 24)

          Text("Missing \(viewModel.missingChaptersCount) chapters")
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal, 24)
            .frame(height: viewModel.missingChaptersCount > 0 ? nil : 0)
            .opacity(viewModel.missingChaptersCount > 0 ? 1 : 0)
        }

        Spacer().frame(height: 24)

        LazyVStack(alignment: .leading, spacing: 24) {
          ForEach(viewModel.chapters) { chapter in
            switch chapter {
            case .chapter(let chapter):
              NavigationLink(value: chapter) {
                makeChapterView(chapter)
              }

            case .missing(let missing):
              HStack(spacing: 16) {
                Spacer()
                  .frame(height: 1)
                  .background(.red)

                Text("Missing \(missing.count) \(missing.count == 1 ? "chapter" : "chapters")")
                  .font(.caption2)
                  .lineLimit(1)
                  .foregroundStyle(.red)
                  .layoutPriority(1)

                Spacer()
                  .frame(height: 1)
                  .background(.red)
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
        Image(uiImage: viewModel.manga.cover.toUIImage() ?? .coverNotFound)
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
        Image(uiImage: viewModel.manga.cover.toUIImage() ?? .coverNotFound)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 100, height: 160)
          .clipShape(RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 8) {
          Text(viewModel.manga.title)
            .foregroundStyle(foregroundColor)
            .font(.headline)

          if let author = viewModel.manga.authors.first {
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
            Image(systemName: getStatusIcon(viewModel.manga.status))
              .resizable()
              .frame(width: 15, height: 15)
              .foregroundStyle(foregroundColor)

            Text(viewModel.manga.status.value.localizedCapitalized)
              .foregroundStyle(foregroundColor)
              .font(.footnote)
          }

          Button {
            Task(priority: .userInitiated) {
              await viewModel.saveManga(!viewModel.manga.isSaved)
            }
          } label: {
            HStack(spacing: 4) {
              Image(systemName: viewModel.manga.isSaved ?  "book.closed.fill" : "book.closed")
                .foregroundStyle(viewModel.isLoading ? .gray : foregroundColor)
                .aspectRatio(1, contentMode: .fill)

              Text(viewModel.manga.isSaved ? "In library" : "Add to library")
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
  private func makeDescriptionView(
    description: String?
  ) -> some View {
    VStack(spacing: 0) {
      ExpandableTextView(
        text: description ?? "",
        isExpanded: $descipitionExpanded,
        font: .footnote,
        textColor: foregroundColor
      )
      .opacity(description == nil ? 0 : 1)
      .padding(.horizontal, 24)
      .id(description ?? "")

      Spacer().frame(height: descipitionExpanded ? 32 : 24)

      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach(viewModel.manga.tags) { tag in
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
