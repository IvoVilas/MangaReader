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
  private let container: NSPersistentContainer

  init(
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    httpClient: HttpClient,
    systemDateTime: SystemDateTimeType,
    container: NSPersistentContainer
  ) {
    self.mangaCrud = mangaCrud
    self.httpClient = httpClient
    self.chapterCrud = chapterCrud
    self.systemDateTime = systemDateTime
    self.container = container
  }

  func refresh() async {
    print("RefreshLibraryUseCase -> Started library refresh...")

    do {
      let context = container.viewContext

      let now = systemDateTime.now
      let sources = try await context.perform {
        try self.mangaCrud
          .getAllMangas(saved: true, moc: context)
          .reduce(into: [String: [String]]()) { $0[$1.sourceId, default: []].append($1.id) }
      }

      await withThrowingTaskGroup(of: Void.self) { taskGroup in
        let context = container.newBackgroundContext()

        for (source, ids) in sources {
          let source = Source.safeInit(from: source)
          let delegate = source.chaptersDelegateType.init(httpClient: self.httpClient)

          print("RefreshLibraryUseCase -> Refresing \(ids.count) \(source.name) mangas ")

          for id in ids {
            taskGroup.addTask {
              let chapters = try await delegate.fetchChapters(mangaId: id)

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
      }

      print("RefreshLibraryUseCase -> Finished refreshing library")
    } catch {
      print("RefreshLibraryUseCase -> Error during library refresh: \(error)")
    }
  }

}
