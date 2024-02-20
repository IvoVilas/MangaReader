//
//  PageCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class PageCrud {

  func createEntity(
    data: String,
    position: Int16,
    chapterPages: ChapterPagesMO,
    moc: NSManagedObjectContext
  ) -> PageMO? {
    return PageMO(
      data: data,
      position: position,
      chapterPages: chapterPages,
      moc: moc
    )
  }

}
