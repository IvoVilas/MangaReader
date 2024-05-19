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
  private let systemDateTime: SystemDateTimeType
  private let moc: NSManagedObjectContext

  init(
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    httpClient: HttpClient,
    systemDateTime: SystemDateTimeType,
    moc: NSManagedObjectContext
  ) {
    self.mangaCrud = mangaCrud
    self.httpClient = httpClient
    self.chapterCrud = chapterCrud
    self.systemDateTime = systemDateTime
    self.moc = moc
  }

  func refresh() async {
    do {
      let context = moc

      let now = systemDateTime.now
      let mangas = try await context.perform {
        try self.mangaCrud
          .getAllMangas(saved: true, moc: context)
          .reduce(into: [String: Source]()) { $0[$1.id] = .safeInit(from: $1.sourceId) }
      }

      print("RefreshLibraryUseCase -> Refreshing \(mangas.count) mangas...")

      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        for (id, source) in mangas {
          let delegate = source.chaptersDelegateType.init(httpClient: self.httpClient)

          taskGroup.addTask {
            let chapters = try await delegate.fetchChapters(mangaId: id)
            let context = PersistenceController.shared.container.newBackgroundContext()

            try context.performAndWait {
              guard let manga = try self.mangaCrud.getManga(id, moc: context) else {
                throw DatasourceError.databaseError("Manga \(id) not found")
              }

              for chapter in chapters {
                _ = try self.chapterCrud.createOrUpdateChapter(
                  id: chapter.id,
                  chapterNumber: chapter.number,
                  title: chapter.title,
                  numberOfPages: chapter.numberOfPages,
                  publishAt: chapter.publishAt,
                  urlInfo: chapter.downloadInfo,
                  manga: manga,
                  moc: context
                )
              }

              self.mangaCrud.updateLastUpdateAt(manga, date: now)

              if !context.saveIfNeeded(rollbackOnError: true).isSuccess {
                throw CrudError.saveError
              }
            }
          }
        }
      }

      print("RefreshLibraryUseCase -> Finished refreshing library")
    } catch {
      print("RefreshLibraryUseCase -> Error during library refresh: \(error)")
    }
  }

}
