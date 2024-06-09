//
//  CoverCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation
import CoreData

final class CoverCrud {

  func getAllCovers(
    moc: NSManagedObjectContext
  ) throws -> [CoverMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cover")

    do {
      guard let results = try moc.fetch(fetchRequest) as? [CoverMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllCovers(
    excludingMangaIds mangaIds: [String],
    moc: NSManagedObjectContext
  ) throws -> [CoverMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cover")

    if !mangaIds.isEmpty {
      fetchRequest.predicate = NSPredicate(format: "NOT mangaId IN %@", mangaIds)
    }

    do {
      guard let results = try moc.fetch(fetchRequest) as? [CoverMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getCover(
    for mangaId: String,
    moc: NSManagedObjectContext
  ) throws -> CoverMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cover")

    fetchRequest.predicate  = NSPredicate(format: "mangaId == %@", mangaId)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [CoverMO]

      return results?.first
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getCovers(
    for mangaId: String,
    moc: NSManagedObjectContext
  ) throws -> [CoverMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cover")

    fetchRequest.predicate = NSPredicate(format: "mangaId == %@", mangaId)

    do {
      guard let results = try moc.fetch(fetchRequest) as? [CoverMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getCoverData(
    for mangaId: String,
    moc: NSManagedObjectContext
  ) throws -> Data? {
    if let cover = try getCover(for: mangaId, moc: moc) {
      return cover.data
    }

    return nil
  }

  func createEntity(
    mangaId: String,
    data: Data,
    moc: NSManagedObjectContext
  ) throws -> CoverMO {
    guard let cover = CoverMO(
      mangaId: mangaId,
      data: data, 
      moc: moc
    ) else { throw CrudError.failedEntityCreation }

    return cover
  }

  func updateEntity(
    _ cover: CoverMO,
    mangaId: String,
    data: Data
  ) {
    cover.mangaId = mangaId
    cover.data    = data
  }

  func createOrUpdateEntity(
    mangaId: String,
    data: Data,
    moc: NSManagedObjectContext
  ) throws -> CoverMO {
    if let local = try getCover(for: mangaId, moc: moc) {
      updateEntity(
        local,
        mangaId: mangaId,
        data: data
      )

      return local
    } else {
      let new = try createEntity(
        mangaId: mangaId,
        data: data,
        moc: moc
      )

      return new
    }
  }

}
