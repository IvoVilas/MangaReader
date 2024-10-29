//
//  PageCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 23/10/2024.
//

import Foundation
import CoreData

final class PageCrud {

  func getPage(
    _ id: String,
    moc: NSManagedObjectContext
  ) throws -> PageMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Page")

    fetchRequest.predicate  = NSPredicate(format: "id == %@", id)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [PageMO]

      return results?.first
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllPages(
    moc: NSManagedObjectContext
  ) throws -> [PageMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Page")

    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PageMO.mangaId, ascending: true)]

    do {
      guard let results = try moc.fetch(fetchRequest) as? [PageMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func createEntity(
    id: String,
    mangaId: String,
    sourceId: String,
    isFavorite: Bool,
    downloadInfo: String,
    filePath: String?,
    moc: NSManagedObjectContext
  ) throws -> PageMO {
    guard let page = PageMO(
      id: id,
      mangaId: mangaId,
      sourceId: sourceId,
      isFavorite: isFavorite,
      downloadInfo: downloadInfo,
      filePath: filePath,
      moc: moc
    ) else {
      throw CrudError.failedEntityCreation
    }

    return page
  }

  func updatePage(
    _ page: PageMO,
    id: String,
    mangaId: String,
    sourceId: String,
    isFavorite: Bool,
    downloadInfo: String,
    filePath: String?
  ) {
    page.id = id
    page.mangaId = mangaId
    page.sourceId = sourceId
    page.isFavorite = isFavorite
    page.downloadInfo = downloadInfo
    page.filePath = filePath
  }

  func createOrUpdatePage(
    id: String,
    mangaId: String,
    sourceId: String,
    isFavorite: Bool,
    downloadInfo: String,
    filePath: String?,
    moc: NSManagedObjectContext
  ) throws -> PageMO {
    if let local = try getPage(id, moc: moc) {
      updatePage(
        local,
        id: id,
        mangaId: mangaId,
        sourceId: sourceId,
        isFavorite: isFavorite,
        downloadInfo: downloadInfo,
        filePath: filePath
      )

      return local
    } else {
      let new = try createEntity(
        id: id,
        mangaId: mangaId,
        sourceId: sourceId,
        isFavorite: isFavorite,
        downloadInfo: downloadInfo,
        filePath: filePath,
        moc: moc
      )

      return new
    }
  }

}
