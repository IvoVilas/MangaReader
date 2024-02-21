//
//  MangaDetailsView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI

struct MangaDetailsView: View {

  @ObservedObject var viewModel: MangaDetailsViewModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack(alignment: .top, spacing: 16) {
          makeImageView(
            viewModel.image,
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
              makeChapterView(chapter)
            }
          }
        }
        .frame(maxWidth: .infinity)
      }
      .padding(.leading, 24)
      .padding(.trailing, 24)
    }
    .refreshable {
      Task {
        await viewModel
          .chaptersDatasource
          .refresh(isForceRefresh: true)
      }
    }
    .onAppear {
      viewModel.onViewAppear()
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
    let mangaId     = "c52b2ce3-7f95-469c-96b0-479524fb7a1a"
    let moc         = PersistenceController.preview.container.viewContext

    let chapterParser = ChapterParser(
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      moc: moc
    )

    return MangaDetailsViewModel(
      chaptersDatasource: MangaChapterDatasource(
        mangaId: mangaId,
        chapterParser: chapterParser,
        mangaCrud: mangaCrud,
        chapterCrud: chapterCrud,
        systemDateTime: SystemDateTime(),
        moc: moc
      ),
      coverDatasource: MangaCoverDatasource(
        mangaId: mangaId,
        mangaParser: MangaParser(),
        mangaCrud: mangaCrud,
        moc: moc
      )
    )
  }

}
