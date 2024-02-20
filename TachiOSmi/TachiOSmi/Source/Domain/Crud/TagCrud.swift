//
//  TagCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class TagCrud {

  func createEntity(
    id: String,
    title: String,
    moc: NSManagedObjectContext
  ) -> TagMO? {
    return TagMO(
      id: id,
      title: title,
      moc: moc
    )
  }

  func addManga(
    _ tag: TagMO,
    manga: MangaMO
  ) {
    tag.mangas.insert(manga)
  }

}
