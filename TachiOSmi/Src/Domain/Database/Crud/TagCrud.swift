//
//  TagCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class TagCrud {

  func getTag(
    _ id: String,
    moc: NSManagedObjectContext
  ) throws -> TagMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")

    fetchRequest.predicate  = NSPredicate(format: "id == %@", id)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [TagMO]

      return results?.first
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllTags(
    moc: NSManagedObjectContext
  ) throws -> [TagMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")

    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TagMO.title, ascending: true)]

    do {
      guard let results = try moc.fetch(fetchRequest) as? [TagMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func createEntity(
    id: String,
    title: String,
    moc: NSManagedObjectContext
  ) throws -> TagMO {
    guard let tag = TagMO(
      id: id,
      title: title,
      moc: moc
    ) else { throw CrudError.failedEntityCreation }

    return tag
  }

  func addManga(
    _ tag: TagMO,
    manga: MangaMO
  ) {
    tag.mangas.insert(manga)
    manga.tags.insert(tag)
  }

  func updateTag(
    _ tag: TagMO,
    id: String,
    title: String,
    manga: MangaMO
  ) {
    tag.id    = id
    tag.title = title

    addManga(tag, manga: manga)
  }

  func createOrUpdateTag(
    id: String,
    title: String,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) throws -> TagMO {
    if let local = try getTag(id, moc: moc) {
      updateTag(
        local,
        id: id,
        title: title,
        manga: manga
      )

      return local
    } else {
      let new = try createEntity(
        id: id,
        title: title,
        moc: moc
      )

      addManga(new, manga: manga)

      return new
    }
  }

}
