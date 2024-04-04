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
  private let inMemory: Bool
  private let sources: [Source]

  private(set) var mangas: [MangaWrapper]

  init(
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    chapterCrud: ChapterCrud,
    inMemory: Bool = false
  ) {
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.chapterCrud = chapterCrud
    self.inMemory = inMemory

    mangas = []
    sources = Source.allSources()
  }

  func refreshLibrary() {
    var res = [MangaWrapper]()

    for source in sources {
      let moc = PersistenceController.getViewMoc(for: source, inMemory: inMemory)

      moc.performAndWait {
        guard let mangas = try? mangaCrud.getAllSavedMangas(moc: moc) else {
          return
        }

        for manga in mangas {
          let unreadChapter = try? chapterCrud.getUnreadChaptersCount(mangaId: manga.id, moc: moc)

          res.append(
            MangaWrapper(
              source: source,
              unreadChapters: unreadChapter ?? 0,
              manga: MangaSearchResult(
                id: manga.id,
                title: manga.title,
                cover: try? coverCrud.getCoverData(for: manga.id, moc: moc),
                isSaved: manga.isSaved
              )
            )
          )
        }
      }
    }

    mangas = res.sorted { $0.manga.title < $1.manga.title }
  }

}

extension MangaLibraryViewModel {

  func buildDetailsViewModel(
    for manga: MangaWrapper
  ) -> MangaDetailsViewModel {
    let source = manga.source
    let manga = manga.manga

    return MangaDetailsViewModel(
      source: source,
      manga: manga,
      mangaCrud: AppEnv.env.mangaCrud,
      chapterCrud: AppEnv.env.chapterCrud,
      coverCrud: AppEnv.env.coverCrud,
      authorCrud: AppEnv.env.authorCrud,
      tagCrud: AppEnv.env.tagCrud,
      httpClient: AppEnv.env.httpClient,
      systemDateTime: AppEnv.env.systemDateTime,
      viewMoc: PersistenceController.getViewMoc(for: source, inMemory: inMemory)
    )
  }

}

extension MangaLibraryViewModel {

  struct MangaWrapper: Hashable, Identifiable {

    let source: Source
    let unreadChapters: Int
    let manga: MangaSearchResult

    var id: String { manga.id }

  }

}
