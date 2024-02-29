//
//  AuthorCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class AuthorCrud {

  func getAuthor(
    _ id: String,
    moc: NSManagedObjectContext
  ) throws -> AuthorMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Author")

    fetchRequest.predicate  = NSPredicate(format: "id == %@", id)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [AuthorMO]

      return results?.first
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func createEntity(
    id: String,
    name: String,
    moc: NSManagedObjectContext
  ) throws -> AuthorMO {
    guard let author = AuthorMO(
      id: id,
      name: name,
      moc: moc
    ) else { throw CrudError.failedEntityCreation }

    return author
  }

  func addManga(
    _ author: AuthorMO,
    manga: MangaMO
  ) {
    author.mangas.insert(manga)
    manga.authors.insert(author)
  }

  func updateAuthor(
    _ author: AuthorMO,
    id: String,
    name: String,
    manga: MangaMO
  ) {
    author.id   = id
    author.name = name

    addManga(author, manga: manga)
  }

  func createOrUpdateAuthor(
    id: String,
    name: String,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) throws -> AuthorMO {
    if let local = try getAuthor(id, moc: moc) {
      updateAuthor(
        local,
        id: id,
        name: name,
        manga: manga
      )

      return local
    } else {
      let new = try createEntity(
        id: id,
        name: name,
        moc: moc
      )

      addManga(new, manga: manga)

      return new
    }
  }

}
