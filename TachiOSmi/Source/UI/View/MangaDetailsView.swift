//
//  MangaDetailsView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI

struct MangaDetailsView: View {

  @ObservedObject var viewModel: MangaDetailsViewModel
  @State private var showAlert = false

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
            .tint(.white)
            .opacity(viewModel.isLoading ? 1 : 0)
            .offset(y: 75)
        }

        Spacer().frame(height: 16)

        Text("\(viewModel.chapters.count) chapters")
          .font(.headline)
          .foregroundStyle(.white)
          .padding(.horizontal, 24)

        Spacer().frame(height: 24)

        VStack(alignment: .leading, spacing: 24) {
          ForEach(viewModel.chapters) { chapter in
            NavigationLink(value: chapter) {
              makeChapterView(chapter)
            }
          }
        }
        .padding(.horizontal, 24)
      }
    }
    .ignoresSafeArea(.all, edges: .top)
    .background(.black)
    .onAppear {
      Task { await viewModel.setupData() }
    }
    .refreshable { viewModel.forceRefresh() }
    .navigationDestination(for: ChapterModel.self) { chapter in
      MangaReaderView(
        viewModel: viewModel.buildReaderViewModel(chapter)
      )
    }
    .onReceive(viewModel.$error) { error in
      if error != nil {
        showAlert.toggle()
      }
    }
    .alert(
      "Error",
      isPresented: $showAlert,
      presenting: viewModel.error,
      actions: { _ in }
    ) { error in
      Text(error.localizedDescription)
    }
  }

  @ViewBuilder
  func makeChapterView(
    _ chapter: ChapterModel
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(chapter.description)
        .font(.subheadline)
        .foregroundStyle(chapter.isRead ? .gray : .white)

      Text(chapter.createdAtDescription)
        .font(.caption2)
        .foregroundStyle(chapter.isRead ? .gray : .white)
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
          .frame(height: 300)
          .clipped()
          .opacity(0.4)
          .overlay {
            LinearGradient(
              gradient: Gradient(colors: [.clear, .black]),
              startPoint: .top,
              endPoint: .bottom
            )
          }

        HStack(spacing: 16) {
          Image(uiImage: viewModel.cover ?? .coverNotFound)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 200)

          VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
              .foregroundStyle(.white)
              .font(.headline)

            if let author = viewModel.authors.first {
              HStack(spacing: 4) {
                Image(systemName: "person")
                  .resizable()
                  .frame(width: 15, height: 15)
                  .foregroundStyle(.white)

                Text(author.name)
                  .foregroundStyle(.white)
                  .font(.footnote)
              }
            }

            HStack(spacing: 4) {
              Image(systemName: getStatusIcon(viewModel.status))
                .resizable()
                .frame(width: 15, height: 15)
                .foregroundStyle(.white)

              Text(viewModel.status.value.localizedCapitalized)
                .foregroundStyle(.white)
                .font(.footnote)
            }
          }

          Spacer()
        }
        .offset(y: 100)
        .padding(.horizontal, 24)
      }

      Text(viewModel.description ?? "")
        .font(.bold(.footnote)())
        .foregroundStyle(.white)
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
              .foregroundStyle(.white)
              .padding(.vertical, 4)
              .padding(.horizontal, 8)
              .background(
                RoundedRectangle(cornerRadius: 4)
                  .stroke(.white, lineWidth: 1)
              )
          }
        }.padding(.horizontal, 24)
      }
      .scrollIndicators(.hidden)
    }
  }

  func getStatusIcon(_ status: MangaStatus) -> String {
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
    let mangaCrud   = MangaCrud()
    let chapterCrud = ChapterCrud()
    let httpClient  = HttpClient()
    let moc         = PersistenceController.preview.container.viewContext
    let manga       = MangaModel(
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

    let chapterParser = ChapterParser(
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      moc: moc
    )

    return MangaDetailsViewModel(
      chaptersDatasource: MangaChapterDatasource(
        mangaId: manga.id,
        httpClient: httpClient,
        chapterParser: chapterParser,
        mangaCrud: mangaCrud,
        chapterCrud: chapterCrud,
        systemDateTime: SystemDateTime(),
        viewMoc: moc
      ),
      detailsDatasource: MangaDetailsDatasource(
        manga: manga,
        httpClient: httpClient,
        mangaParser: MangaParser(),
        mangaCrud: mangaCrud,
        coverCrud: CoverCrud(),
        authorCrud: AuthorCrud(),
        tagCrud: TagCrud(),
        viewMoc: moc
      )
    )
  }

}
