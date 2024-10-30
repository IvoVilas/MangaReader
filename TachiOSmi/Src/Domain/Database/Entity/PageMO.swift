//
//  PageMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 23/10/2024.
//

import Foundation
import CoreData

class PageMO: NSManagedObject {

  @NSManaged var pageId: String
  @NSManaged var mangaId: String
  @NSManaged var chapterId: String
  @NSManaged var pageNumber: Int64
  @NSManaged var sourceId: String
  @NSManaged var isFavorite: Bool
  @NSManaged var downloadInfo: String
  @NSManaged var filePath: String?

  convenience init?(
    pageId: String,
    mangaId: String,
    chapterId: String,
    pageNumber: Int64,
    sourceId: String,
    isFavorite: Bool,
    downloadInfo: String,
    filePath: String?,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "Page", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.pageId = pageId
    self.mangaId = mangaId
    self.chapterId = chapterId
    self.pageNumber = pageNumber
    self.sourceId = sourceId
    self.isFavorite = isFavorite
    self.downloadInfo = downloadInfo
    self.filePath = filePath
  }

}
