//
//  MangaMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

class MangaMO: NSManagedObject {

  @NSManaged var id: String
  @NSManaged var title: String
  @NSManaged var synopsis: String?
  @NSManaged var statusId: Int16
  @NSManaged var lastUpdateAt: Date?
  @NSManaged var isSaved: Bool
  @NSManaged var readingDirection: Int16

  // Relationships
  @NSManaged var chapters: Set<ChapterMO>
  @NSManaged var tags: Set<TagMO>
  @NSManaged var authors: Set<AuthorMO>

  convenience init?(
    id: String,
    title: String,
    synopsis: String?,
    statusId: Int16,
    lastUpdateAt: Date?,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "Manga", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.id               = id
    self.title            = title
    self.synopsis         = synopsis
    self.statusId         = statusId
    self.lastUpdateAt     = lastUpdateAt
    self.isSaved          = false
    self.readingDirection = 0

    self.chapters = Set<ChapterMO>()
    self.tags     = Set<TagMO>()
    self.authors  = Set<AuthorMO>()
  }

}
