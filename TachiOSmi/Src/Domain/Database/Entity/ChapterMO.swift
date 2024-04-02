//
//  ChapterMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

class ChapterMO: NSManagedObject {

  @NSManaged var id: String
  @NSManaged var chapter: NSNumber?
  @NSManaged var title: String?
  @NSManaged var numberOfPages: Int16
  @NSManaged var publishAt: Date
  @NSManaged var urlInfo: String
  @NSManaged var isRead: Bool
  @NSManaged var lastPageRead: NSNumber? // Int16

  // Relationships
  @NSManaged var manga: MangaMO

  convenience init?(
    id: String,
    chapter: Double?,
    title: String?,
    numberOfPages: Int16,
    publishAt: Date,
    urlInfo: String,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "Chapter", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.id            = id
    self.chapter       = chapter as? NSNumber
    self.title         = title
    self.numberOfPages = numberOfPages
    self.publishAt     = publishAt
    self.urlInfo       = urlInfo
    self.isRead        = false
    self.lastPageRead  = nil

    self.manga = manga
  }

}
