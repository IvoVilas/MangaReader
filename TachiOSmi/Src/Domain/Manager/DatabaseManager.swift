//
//  DatabaseManager.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 19/05/2024.
//

import Foundation
import CoreData

final class DatabaseManager {

  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let tagCrud: TagCrud
  private let authorCrud: AuthorCrud
  private let coverCrud: CoverCrud
  private let formatter: Formatter
  private let persistenceContainer: NSPersistentContainer

  init(
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    tagCrud: TagCrud,
    authorCrud: AuthorCrud,
    coverCrud: CoverCrud,
    formatter: Formatter,
    persistenceContainer: NSPersistentContainer
  ) {
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.tagCrud = tagCrud
    self.authorCrud = authorCrud
    self.coverCrud = coverCrud
    self.formatter = formatter
    self.persistenceContainer = persistenceContainer

  }

  func cleanDatabase() -> Result<(Int, Int), DatasourceError> {
    do {
      let context = persistenceContainer.viewContext
      var mangaCount = 0
      var coverCount = 0

      try context.performAndWait {
        let mangas = try self.mangaCrud.getAllMangas(saved: false, moc: context)
        let ids = mangas.map { $0.id }

        for manga in mangas {
          context.delete(manga)
          mangaCount += 1
        }

        for id in ids {
          let covers = try self.coverCrud.getCovers(for: id, moc: context)

          for cover in covers {
            context.delete(cover)
            coverCount += 1
          }
        }

        if context.hasChanges {
          try context.save()
        }

        print("DatabaseManager -> Deleted \(mangaCount) mangas and \(coverCount) covers")
      }

      return .success((mangaCount, coverCount))
    } catch {
      print("DatabaseManager -> Error during database cleaning: \(error)")

      let error = DatasourceError.catchError(error) ?? .otherError("Unknown error")
      return .failure(error)
    }
  }

  // TODO: Dump covers as well
  // TODO: Dump "lost entites"
  func dumpDatabase() -> Result<URL, DatasourceError> {
    let converter = DataToJsonConverter(formatter: formatter)
    let context = persistenceContainer.viewContext
    var json = [String: Any]()
    var mangasJson = [[String: Any]]()
    var chaptersJson = [[String: Any]]()

    do {
      var mangaIds = [String]()
      var chapterIds = [String]()
      var tagIds = [String]()
      var authorIds = [String]()

      try context.performAndWait {
        let mangas = try self.mangaCrud.getAllMangas(moc: context)

        for manga in mangas {
          var mangaJson = converter.convert(manga)

          mangaJson["chapters"] = manga.chapters.map { converter.convert($0) }
          mangaJson["tags"] = manga.tags.map { converter.convert($0) }
          mangaJson["authors"] = manga.authors.map { converter.convert($0) }

          mangaIds.append(manga.id)
          chapterIds.append(contentsOf: manga.chapters.map { $0.id })
          tagIds.append(contentsOf: manga.tags.map { $0.id })
          authorIds.append(contentsOf: manga.authors.map { $0.id })

          mangasJson.append(mangaJson)
        }

        let chapters = try self.chapterCrud.getAllChapters(excludingIds: chapterIds, moc: context)
        chaptersJson = chapters.map { converter.convert($0) }
      }

      json["mangas"] = mangasJson
      json["chapters"] = chaptersJson

      let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
      let url = FileManager.default.temporaryDirectory.appendingPathComponent("database.json")
      try jsonData.write(to: url)

      print("DatabaseManager -> Database dump file created")

      return .success(url)
    } catch {
      print("DatabaseManager -> Error during database dump: \(error)")

      let error = DatasourceError.catchError(error) ?? .otherError("Unknown error")
      return .failure(error)
    }
  }

}
