//
//  RefreshLibraryUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import CoreData

final class RefreshLibraryUseCase {

  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let httpClient: HttpClient
  private let viewMoc: NSManagedObjectContext

  init(
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    httpClient: HttpClient,
    viewMoc: NSManagedObjectContext
  ) {
    self.mangaCrud = mangaCrud
    self.httpClient = httpClient
    self.chapterCrud = chapterCrud
    self.viewMoc = viewMoc
  }

  func refresh() async {
    do {
      let localMangas = try await viewMoc.perform {
        try self.mangaCrud.getAllSavedMangas(moc: self.viewMoc)
      }

      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        for manga in localMangas {
          let source = Source.safeInit(from: manga.sourceId)
          let delegate = source.chaptersDelegateType.init(httpClient: self.httpClient)

          taskGroup.addTask {
            let chapters = try await delegate.fetchChapters(mangaId: manga.id)

            try self.viewMoc.performAndWait {
              for chapter in chapters {
                _ = try self.chapterCrud.createOrUpdateChapter(
                  id: chapter.id,
                  chapterNumber: chapter.number,
                  title: chapter.title,
                  numberOfPages: chapter.numberOfPages,
                  publishAt: chapter.publishAt,
                  urlInfo: chapter.downloadInfo,
                  manga: manga,
                  moc: self.viewMoc
                )
              }
            }
          }
        }
      }
    } catch {
      print("RefreshLibraryUseCase -> Error during refresh: \(error)")
    }
  }

}
