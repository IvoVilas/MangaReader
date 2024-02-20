//
//  AuthorCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class AuthorCrud {

  func createEntity(
    id: String,
    name: String,
    moc: NSManagedObjectContext
  ) -> AuthorMO? {
    return AuthorMO(
      id: id,
      name: name,
      moc: moc
    )
  }

  func addManga(
    _ author: AuthorMO,
    manga: MangaMO
  ) {
    author.mangas.insert(manga)
  }

}
