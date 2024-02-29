//
//  CoverMO.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation
import CoreData

class CoverMO: NSManagedObject {

  @NSManaged var mangaId: String
  @NSManaged var data: Data

  // Relationships
  convenience init?(
    mangaId: String,
    data: Data,
    moc: NSManagedObjectContext
  ) {
    guard let entity = NSEntityDescription.entity(forEntityName: "Cover", in: moc) else {
      return nil
    }

    self.init(entity: entity, insertInto: moc)

    self.mangaId = mangaId
    self.data    = data
  }

}
