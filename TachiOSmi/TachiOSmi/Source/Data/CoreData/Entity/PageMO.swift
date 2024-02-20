//
//  PageMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

class PageMO: NSManagedObject {

  @NSManaged var data: String
  @NSManaged var position: Int16

  // Relationships
  @NSManaged var chapterPages: ChapterPagesMO

  convenience init?(
    data: String,
    position: Int16,
    chapterPages: ChapterPagesMO,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "Page", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.data     = data
    self.position = position

    self.chapterPages = chapterPages
  }

}
