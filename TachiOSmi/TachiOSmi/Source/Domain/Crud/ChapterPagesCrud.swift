//
//  ChapterPagesCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class ChapterPagesCrud {

  func createEntity(
    baseUrl: String,
    chapterHash: String,
    chapter: ChapterMO,
    moc: NSManagedObjectContext
  ) -> ChapterPagesMO? {
    return ChapterPagesMO(
      baseUrl: baseUrl,
      chapterHash: chapterHash,
      chapter: chapter,
      moc: moc
    )
  }

  func addPage(
    _ chapter: ChapterPagesMO,
    page: PageMO
  ) {
    chapter.pages.insert(page)
  }

  func addPages(
    _ chapter: ChapterPagesMO,
    pages: PageMO
  ) {
    for page in chapter.pages {
      chapter.pages.insert(page)
    }
  }

}
