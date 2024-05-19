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
  private let coverCrud: CoverCrud
  private let persistenceContainer: NSPersistentContainer

  init(
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    persistenceContainer: NSPersistentContainer
  ) {
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
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
      print("DatabaseManager -> Error cleaning database: \(error)")

      let error = DatasourceError.catchError(error) ?? .otherError("Unknown error")
      return .failure(error)
    }
  }

}
