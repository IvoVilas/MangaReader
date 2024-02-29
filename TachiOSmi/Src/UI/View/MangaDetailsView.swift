//
//  MangaDetailsView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI

struct MangaDetailsView: View {

  @ObservedObject var viewModel: MangaDetailsViewModel
  @State private var toast: Toast?

  private let backgroundColor: Color = .black
  private let foregroundColor: Color = .white

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
                    await viewModel.loadNextChaptersIfNeeded(chapter.id)
                  }
                }
            }
          }
        }
        .padding(.horizontal, 24)
      }
    }
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
        viewModel: viewModel.buildReaderViewModel(chapter, delegateType: MangadexPagesDelegate.self)
      )
    }
    .toastView(toast: $toast)
    .onReceive(viewModel.$error) { error in
      if let error {
        toast = Toast(
          style: .error,
          message: error.localizedDescription
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
        .foregroundStyle(chapter.isRead ? .gray : foregroundColor)

      Text(chapter.createdAtDescription)
        .font(.caption2)
        .foregroundStyle(chapter.isRead ? .gray : foregroundColor)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func makeHeaderView() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .top) {
        Image(uiImage: viewModel.cover ?? .coverNotFound)
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
          .offset(y: 100)
          .padding(.horizontal, 24)
      }
    }
  }

  @ViewBuilder
  private func makeInfoView() -> some View {
    HStack(spacing: 16) {
      Image(uiImage: viewModel.cover ?? .coverNotFound)
        .resizable()
        .aspectRatio(contentMode: .fit)
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
      }

      Spacer()
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

  static func buildPreviewViewModel() -> MangaDetailsViewModel {
    let systemDateTime = SystemDateTime()
    let mangaCrud = MangaCrud()
    let coverCrud = CoverCrud()
    let chapterCrud = ChapterCrud()
    let httpClient = HttpClient()
    let moc = PersistenceController.preview.container.viewContext
    let manga = MangaModel(
      id: "c52b2ce3-7f95-469c-96b0-479524fb7a1a",
      title: "Jujutsu Kaisen",
      description: "Yuuji is a genius at track and field. But he has zero interest running around in circles, he's happy as a clam in the Occult Research Club. Although he's only in the club for kicks, things get serious when a real spirit shows up at school! Life's about to get really strange in Sugisawa Town #3 High School!",
      status: .ongoing,
      cover: UIImage.jujutsuCover.jpegData(compressionQuality: 1),
      tags: [
        TagModel(id: "1", title: "Action"),
        TagModel(id: "2", title: "Drama"),
        TagModel(id: "3", title: "Horror"),
        TagModel(id: "4", title: "School life"),
        TagModel(id: "5", title: "Shounen"),
        TagModel(id: "6", title: "Supernatural"),
        TagModel(id: "7", title: "Manga"),
        TagModel(id: "8", title: "Ghosts")
      ],
      authors: [AuthorModel(id: "1", name: "Akutami Gege")]
    )

    return MangaDetailsViewModel(
      chaptersDatasource: ChaptersDatasource(
        mangaId: manga.id,
        delegate: MangadexChaptersDelegate(
          httpClient: httpClient,
          chapterParser: ChapterParser(),
          systemDateTime: systemDateTime
        ),
        mangaCrud: mangaCrud,
        chapterCrud: chapterCrud,
        systemDateTime: systemDateTime, 
        viewMoc: moc
      ),
      detailsDatasource: DetailsDatasource(
        manga: manga,
        delegate: MangadexDetailsDelegate(
          httpClient: httpClient,
          coverCrud: coverCrud,
          mangaParser: MangaParser()
        ),
        mangaCrud: mangaCrud,
        coverCrud: coverCrud,
        authorCrud: AuthorCrud(),
        tagCrud: TagCrud(),
        viewMoc: moc
      )
    )
  }

}
