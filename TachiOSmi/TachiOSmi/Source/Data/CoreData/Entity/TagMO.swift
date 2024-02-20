//
//  TagMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

class TagMO: NSManagedObject {

  @NSManaged var id: String
  @NSManaged var title: String

  // Relationships
  @NSManaged var mangas: Set<MangaMO>

  convenience init?(
    id: String,
    title: String,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "Tag", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.id    = id
    self.title = title
    
    self.mangas = Set<MangaMO>()
  }

}
