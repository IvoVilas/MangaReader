//
//  PageMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 23/10/2024.
//

import Foundation
import CoreData

class PageMO: NSManagedObject {

  @NSManaged var id: String
  @NSManaged var mangaId: String
  @NSManaged var sourceId: String
  @NSManaged var isFavorite: Bool
  @NSManaged var downloadInfo: String
  @NSManaged var filePath: String?

  convenience init?(
    id: String,
    mangaId: String,
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

    self.id = id
    self.mangaId = mangaId
    self.sourceId = sourceId
    self.isFavorite = isFavorite
    self.downloadInfo = downloadInfo
    self.filePath = filePath
  }

}
