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

        let covers = try self.coverCrud.getAllCovers(
          excludingMangaIds: try self.mangaCrud.getAllMangas(saved: true, moc: context).map { $0.id },
          moc: context
        )

        for manga in mangas {
          context.delete(manga)
          mangaCount += 1
        }

        for cover in covers {
          context.delete(cover)
          coverCount += 1
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
  func dumpDatabase() -> Result<URL, DatasourceError> {
    let converter = DataToJsonConverter(formatter: formatter)
    let context = persistenceContainer.viewContext
    var json = [String: Any]()
    var mangasJson = [[String: Any]]()
    var chaptersJson = [[String: Any]]()
    var tagsJson = [[String: Any]]()
    var authorsJson = [[String: Any]]()

    do {
      var mangaIds = [String]()
      var chapterIds = [String]()

      try context.performAndWait {
        let mangas = try self.mangaCrud.getAllMangas(moc: context)

        for manga in mangas {
          var mangaJson = converter.convert(manga)

          mangaJson["chapters"] = manga.chapters.map { converter.convert($0) }
          mangaJson["tags"] = manga.tags.map { converter.convert($0) }
          mangaJson["authors"] = manga.authors.map { converter.convert($0) }

          mangaIds.append(manga.id)
          chapterIds.append(contentsOf: manga.chapters.map { $0.id })

          mangasJson.append(mangaJson)
        }

        let chapters = try self.chapterCrud.getAllChapters(excludingIds: chapterIds, moc: context)
        chaptersJson = chapters.map { converter.convert($0) }

        let tags = try self.tagCrud.getAllTags(moc: context)
        tagsJson = tags.map { converter.convert($0) }

        let authors = try self.authorCrud.getAllAuthors(moc: context)
        authorsJson = authors.map { converter.convert($0) }
      }

      json["mangas"] = mangasJson
      json["chapters"] = chaptersJson
      json["tags"] = tagsJson
      json["authors"] = authorsJson

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

  func importDatabase(_ data: Data) -> EmptyResult<DatasourceError> {
    print("DatabaseManager -> Started database import...")

    do {
      let converter = JsonToDataConverter(
        mangaCrud: mangaCrud,
        chapterCrud: chapterCrud,
        authorCrud: authorCrud,
        tagCrud: tagCrud,
        formatter: formatter
      )

      guard 
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let mangas = json["mangas"] as? [[String: Any]]
      else {
        throw DatasourceError.errorParsingResponse("Selected file is not valid")
      }

      let context = persistenceContainer.newBackgroundContext()

      try context.performAndWait {
        _ = mangas.map { converter.toManga($0, moc: context) }

        if context.hasChanges {
          try context.save()
        }
      }

      print("DatabaseManager -> Finished database import")

      return .success
    } catch {
      print("DatabaseManager -> Error during database import: \(error)")

      let error = DatasourceError.catchError(error) ?? .otherError("Unknown error")
      return .failure(error)
    }
  }

}
