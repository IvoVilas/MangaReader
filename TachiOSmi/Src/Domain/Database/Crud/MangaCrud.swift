//
//  MangaCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class MangaCrud { }

// MARK: - Get
extension MangaCrud {

  func getManga(
    _ id: String,
    moc: NSManagedObjectContext
  ) throws -> MangaMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")

    fetchRequest.predicate  = NSPredicate(format: "id == %@", id)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [MangaMO]

      return results?.first
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllMangas(
    moc: NSManagedObjectContext
  ) throws -> [MangaMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")

    do {
      guard let results = try moc.fetch(fetchRequest) as? [MangaMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllMangasWithChapters(
    moc: NSManagedObjectContext
  ) throws -> [MangaMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")

    fetchRequest.predicate = NSPredicate(format: "%K.@count > 0", #keyPath(MangaMO.chapters))

    do {
      guard let results = try moc.fetch(fetchRequest) as? [MangaMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllMangasIdsWithoutCovers(
    fromIds ids: [String] = [],
    moc: NSManagedObjectContext
  ) throws -> [String] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")
    let predicate: NSPredicate

    if ids.isEmpty {
      predicate = NSPredicate(format: "coverArt == nil")
    } else {
      predicate = NSPredicate(format: "coverArt == nil AND id IN %@", ids)
    }

    // TODO: Only get ids
    fetchRequest.predicate = predicate

    do {
      guard let results = try moc.fetch(fetchRequest) as? [MangaMO] else {
        throw CrudError.wrongRequestType
      }

      return results.map { $0.id }
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllSavedMangas(
    moc: NSManagedObjectContext
  ) throws -> [MangaMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")

    fetchRequest.predicate = NSPredicate(format: "isSaved == true")

    do {
      guard let results = try moc.fetch(fetchRequest) as? [MangaMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

}

// MARK: - Create or Update
extension MangaCrud {

  func createOrUpdateManga(
    id: String,
    title: String,
    synopsis: String?,
    status: MangaStatus,
    source: Source,
    readingDirection: ReadingDirection,
    moc: NSManagedObjectContext
  ) throws -> MangaMO {
    if let local = try getManga(id, moc: moc) {
      updateManga(
        local,
        title: title,
        synopsis: synopsis,
        status: status,
        moc: moc
      )

      return local
    }

    return try createEntity(
      id: id,
      title: title,
      synopsis: synopsis,
      status: status,
      source: source,
      readingDirection: readingDirection,
      moc: moc
    )
  }

}

// MARK: - Create
extension MangaCrud {

  func createEntity(
    id: String,
    title: String,
    synopsis: String?,
    status: MangaStatus,
    source: Source,
    readingDirection: ReadingDirection,
    moc: NSManagedObjectContext
  ) throws -> MangaMO {
    guard let manga = MangaMO(
      id: id,
      title: title,
      synopsis: synopsis,
      statusId: status.id,
      lastUpdateAt: nil,
      sourceId: source.id,
      readingDirectionId: readingDirection.id,
      moc: moc
    ) else { throw CrudError.failedEntityCreation }

    return manga
  }

}

// MARK: - Update
extension MangaCrud {

  func updateManga(
    _ manga: MangaMO,
    title: String,
    synopsis: String?,
    status: MangaStatus,
    moc: NSManagedObjectContext
  ) {
    manga.title    = title
    manga.statusId = status.id

    if let synopsis { manga.synopsis = synopsis }
  }

  func updateLastUpdateAt(
    _ manga: MangaMO,
    date: Date?
  ) {
    manga.lastUpdateAt = date
  }

  func updateIsSaved(
    _ manga: MangaMO,
    isSaved: Bool
  ) {
    manga.isSaved = isSaved
  }

  func updateReadingDirection(
    _ manga: MangaMO,
    direction: ReadingDirection
  ) {
    manga.readingDirection = direction.id
  }

}
