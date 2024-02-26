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

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack(alignment: .top, spacing: 16) {
          makeImageView(
            viewModel.cover,
            isLoading: viewModel.isImageLoading
          )

          VStack(spacing: 0) {
            Spacer().frame(height: 64)

            Text(viewModel.title)
              .font(.title2)
          }
          .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)

        Spacer().frame(height: 24)

        Text("\(viewModel.chapters.count) chapters")

        Spacer().frame(height: 24)

        ZStack(alignment: .top) {
          ProgressView()
            .progressViewStyle(.circular)
            .opacity(viewModel.isLoading ? 1 : 0)

          VStack(alignment: .leading, spacing: 24) {
            ForEach(viewModel.chapters) { chapter in
              NavigationLink(value: chapter) {
                makeChapterView(chapter)
              }
            }
          }
          .navigationDestination(for: ChapterModel.self) { chapter in
            MangaReaderView(
              viewModel: viewModel.buildChapterReaderViewModel(for: chapter.id)
            )
          }
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.leading, 24)
      .padding(.trailing, 24)
    }
    .refreshable { viewModel.forceRefresh() }
    .task { await viewModel.setupData() }
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
        .font(.headline)

      Text(chapter.createdAtDescription)
        .font(.caption)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func makeImageView(
    _ image: UIImage?,
    isLoading: Bool
  ) -> some View {
    ZStack {
      Image(uiImage: image ?? UIImage(resource: .coverNotFound))
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 200)

      ProgressView()
        .progressViewStyle(.circular)
        .frame(width: 150, height: 200, alignment: .center)
        .border(.gray, width: 1)
        .opacity(isLoading ? 1 : 0)
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
      description: "This is our Jujutsu Kaisen",
      status: .ongoing,
      cover: UIImage.jujutsuCover,
      tags: [],
      authors: []
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
        viewMoc: moc
      )
    )
  }

}
