//
//  MangaLibraryViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 09/03/2024.
//

import Foundation
import SwiftUI
import CoreData

@Observable
final class MangaLibraryViewModel {

  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let chapterCrud: ChapterCrud
  private let viewMoc: NSManagedObjectContext

  private(set) var mangas: [MangaWrapper]

  init(
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    chapterCrud: ChapterCrud,
    viewMoc: NSManagedObjectContext
  ) {
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.chapterCrud = chapterCrud
    self.viewMoc = viewMoc

    mangas = []
  }

  func refreshLibrary() {
    var res = [MangaWrapper]()

    viewMoc.performAndWait {
      guard let mangas = try? mangaCrud.getAllSavedMangas(moc: self.viewMoc) else {
        return
      }

      for manga in mangas {
        let unreadChapter = try? chapterCrud.getUnreadChaptersCount(
          mangaId: manga.id,
          moc: self.viewMoc
        )

        res.append(
          MangaWrapper(
            unreadChapters: unreadChapter ?? 0,
            manga: MangaSearchResult(
              id: manga.id,
              title: manga.title,
              cover: try? coverCrud.getCoverData(for: manga.id, moc: self.viewMoc),
              isSaved: manga.isSaved
            )
          )
        )
      }
    }

    mangas = res.sorted { $0.manga.title < $1.manga.title }
  }

}

extension MangaLibraryViewModel {

  func buildDetailsViewModel(
    for manga: MangaWrapper
  ) -> MangaDetailsViewModel {
    let manga = manga.manga

    return MangaDetailsViewModel(
      source: .mangadex, // TODO: Get manga source from database
      manga: manga,
      mangaCrud: AppEnv.env.mangaCrud,
      chapterCrud: AppEnv.env.chapterCrud,
      coverCrud: AppEnv.env.coverCrud,
      authorCrud: AppEnv.env.authorCrud,
      tagCrud: AppEnv.env.tagCrud,
      httpClient: AppEnv.env.httpClient,
      systemDateTime: AppEnv.env.systemDateTime,
      viewMoc: viewMoc
    )
  }

}

extension MangaLibraryViewModel {

  struct MangaWrapper: Hashable, Identifiable {

    let unreadChapters: Int
    let manga: MangaSearchResult

    var id: String { manga.id }

  }

}
