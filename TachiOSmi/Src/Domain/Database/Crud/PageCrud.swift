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
  ) -> PageMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Page")
    
    fetchRequest.predicate  = NSPredicate(format: "pageId == %@", id)
    fetchRequest.fetchLimit = 1
    
    let results = try? moc.fetch(fetchRequest) as? [PageMO]
    
    return results?.first
  }

  func getAllPages(
    moc: NSManagedObjectContext
  ) -> [PageMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Page")

    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PageMO.mangaId, ascending: true)]

    let results = try? moc.fetch(fetchRequest) as? [PageMO]

    return results ?? []
  }

  func createEntity(
    pageId: String,
    mangaId: String,
    chapterId: String,
    pageNumber: Int,
    sourceId: String,
    isFavorite: Bool,
    downloadInfo: String,
    filePath: String?,
    moc: NSManagedObjectContext
  ) -> PageMO? {
    guard let page = PageMO(
      pageId: pageId,
      mangaId: mangaId,
      chapterId: chapterId,
      pageNumber: Int64(pageNumber),
      sourceId: sourceId,
      isFavorite: isFavorite,
      downloadInfo: downloadInfo,
      filePath: filePath,
      moc: moc
    ) else {
      return nil
    }

    return page
  }

  func updatePage(
    _ page: PageMO,
    pageId: String,
    mangaId: String,
    chapterId: String,
    pageNumber: Int,
    sourceId: String,
    isFavorite: Bool,
    downloadInfo: String,
    filePath: String?
  ) {
    page.pageId = pageId
    page.mangaId = mangaId
    page.chapterId = chapterId
    page.pageNumber = Int64(pageNumber)
    page.sourceId = sourceId
    page.isFavorite = isFavorite
    page.downloadInfo = downloadInfo
    page.filePath = filePath
  }

  func createOrUpdatePage(
    pageId: String,
    mangaId: String,
    chapterId: String,
    pageNumber: Int,
    sourceId: String,
    isFavorite: Bool,
    downloadInfo: String,
    filePath: String?,
    moc: NSManagedObjectContext
  ) -> PageMO? {
    if let local = getPage(pageId, moc: moc) {
      updatePage(
        local,
        pageId: pageId,
        mangaId: mangaId,
        chapterId: chapterId,
        pageNumber: pageNumber,
        sourceId: sourceId,
        isFavorite: isFavorite,
        downloadInfo: downloadInfo,
        filePath: filePath
      )

      return local
    } else {
      let new = createEntity(
        pageId: pageId,
        mangaId: mangaId,
        chapterId: chapterId,
        pageNumber: pageNumber,
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
