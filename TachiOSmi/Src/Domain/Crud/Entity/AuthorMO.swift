//
//  AuthorMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

class AuthorMO: NSManagedObject {

  @NSManaged var id: String
  @NSManaged var name: String

  // Relationships
  @NSManaged var mangas: Set<MangaMO>

  convenience init?(
    id: String,
    name: String,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "Author", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.id   = id
    self.name = name

    self.mangas = Set<MangaMO>()
  }

}
