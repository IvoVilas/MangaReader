//
//  MangaDetailsView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 04/04/2024.
//

import SwiftUI

struct MangaDetailsView: View {

  let viewModel: MangaDetailsViewModel

  @State private var toast: Toast?
  @State private var isExpanded: Bool = false
  @State private var shouldShowExpandButton: Bool = false
  @State private var descriptionWidth = CGFloat.zero

  private let backgroundColor: Color = .white
  private let foregroundColor: Color = .black

  var body: some View {
    ZStack(alignment: .top) {
      ScrollView {
        VStack(spacing: 16) {
          ZStack(alignment: .topLeading) {
            ZStack(alignment: .bottom) {
              backgroundView()

              infoView()
                .padding(.horizontal, 24)
            }

            navbarView()
              .padding(.horizontal, 24)
              .offset(y: 64)
          }

          ZStack(alignment: .top) {
            Text(viewModel.manga.description ?? "")
              .font(.footnote)
              .foregroundStyle(foregroundColor)
              .opacity(viewModel.manga.description == nil ? 0 : 1)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(
                GeometryReader { geometry in
                  Color.clear.onAppear {
                    let width = geometry.size.width

                    let textSize = textSizeWithoutLimit(availableWidth: width)
                    let limitedTextSize = textSizeWithLimit(availableWidth: width)

                    shouldShowExpandButton = textSize.height > limitedTextSize.height
                    descriptionWidth = width
                  }
                }
              )
              .padding(.horizontal, 24)
              .id(viewModel.manga.description ?? "")

            VStack(alignment: .leading, spacing: 0) {
              ZStack(alignment: .bottom) {
                LinearGradient(
                  gradient: Gradient(colors: [.clear, .white.opacity(0.8), .white]),
                  startPoint: .top,
                  endPoint: .bottom
                )
                .opacity(!isExpanded && shouldShowExpandButton ? 1 : 0)

                Button {
                  withAnimation {
                    isExpanded.toggle()
                  }
                } label: {
                  Image(isExpanded ? "expand_less" : "expand_more")
                    .foregroundColor(.black)
                }
                .contentTransition(.symbolEffect(.automatic))
                .opacity(shouldShowExpandButton ? 1 : 0)
              }
              .padding(.horizontal, 24)

              Spacer()
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)

              tagsView()
                .background(backgroundColor)

              Spacer()
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)

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
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(backgroundColor)

              Spacer()
                .frame(height: 24)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)

              chaptersView()
                .padding(.horizontal, 24)
                .background(backgroundColor)
            }
            .offset(
              y: textOffset(availableWidth: descriptionWidth)
            )
          }
        }
      }
      .scrollIndicators(.hidden)

      ProgressView()
        .controlSize(.regular)
        .progressViewStyle(.circular)
        .tint(foregroundColor)
        .opacity(viewModel.isLoading ? 1 : 0)
        .offset(y: 75)
    }
    .navigationBarBackButtonHidden(true)
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
          gradient: Gradient(colors: [.clear, backgroundColor]),
          startPoint: .top,
          endPoint: .bottom
        )
      }
  }

  @ViewBuilder
  private func navbarView() -> some View {
    CustomBackAction(tintColor: foregroundColor)
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
        .animation(nil, value: isExpanded)

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

  @ViewBuilder
  private func tagsView() -> some View {
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

  @ViewBuilder
  private func chaptersView() -> some View {
    LazyVStack(alignment: .leading, spacing: 24) {
      ForEach(viewModel.chapters) { chapter in
        switch chapter {
        case .chapter(let chapter):
          NavigationLink(value: chapter) {
            chapterView(chapter)
          }

        case .missing(let missing):
          missingChapterView(missing)
        }
      }
    }
  }

  @ViewBuilder
  func chapterView(
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
  func missingChapterView(
    _ missing: MissingChaptersModel
  ) -> some View {
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

  private func textOffset(
    availableWidth: CGFloat
  ) -> CGFloat {
    if isExpanded {
      return textSizeWithoutLimit(
        availableWidth: availableWidth
      ).height + 16
    }

    return textSizeWithLimit(
      availableWidth: availableWidth
    ).height
  }

  private func textSizeWithoutLimit(
    availableWidth: CGFloat
  ) -> CGSize {
    let text = viewModel.manga.description ?? ""

    let textSize = text.boundingRect(
      with: CGSize(
        width: availableWidth,
        height: .infinity
      ),
      options: .usesLineFragmentOrigin,
      attributes: [.font: Font.footnote.uiFont],
      context: nil
    ).size

    return textSize
  }

  private func textSizeWithLimit(
    availableWidth: CGFloat
  ) -> CGSize {
    let text = viewModel.manga.description ?? ""

    let textSize = text.boundingRect(
      with: CGSize(
        width: availableWidth,
        height: 3 * Font.footnote.uiFont.lineHeight
      ),
      options: .usesLineFragmentOrigin,
      attributes: [.font: Font.footnote.uiFont],
      context: nil
    ).size

    return textSize
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

extension Font {

  var uiFont: UIFont {
    let style: UIFont.TextStyle

    switch self {
    case .largeTitle:
      style = .largeTitle

    case .title:
      style = .title1

    case .title2:
      style = .title2

    case .title3:
      style = .title3

    case .headline:
      style = .headline

    case .subheadline:
      style = .subheadline

    case .callout:
      style = .callout

    case .caption:
      style = .caption1

    case .caption2:
      style = .caption2

    case .footnote:
      style = .footnote

    case .body:
      fallthrough

    default:
      style = .body
    }
    return  UIFont.preferredFont(forTextStyle: style)
  }

}
