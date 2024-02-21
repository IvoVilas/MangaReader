//
//  ChapterPagesMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

class ChapterPagesMO: NSManagedObject {

  @NSManaged var baseUrl: String
  @NSManaged var chapterHash: String

  // Relationships
  @NSManaged var pages: Set<PageMO>
  @NSManaged var chapter: ChapterMO

  convenience init?(
    baseUrl: String,
    chapterHash: String,
    chapter: ChapterMO,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "ChapterPages", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.baseUrl     = baseUrl
    self.chapterHash = chapterHash
    
    self.pages   = Set<PageMO>()
    self.chapter = chapter
  }

}
