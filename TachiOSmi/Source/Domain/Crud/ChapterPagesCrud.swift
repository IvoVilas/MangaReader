//
//  ChapterPagesCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class ChapterPagesCrud {

  func getChapterPages(
    for chapterId: String,
    moc: NSManagedObjectContext
  ) throws -> ChapterPagesMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChapterPages")

    fetchRequest.predicate = NSPredicate(format: "chapter.id == %@", chapterId)

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterPagesMO] else {
        throw CrudError.wrongRequestType
      }

      return results.first
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func createOrUpdateEntity(
    chapterId: String,
    baseUrl: String,
    chapterHash: String,
    chapter: ChapterMO,
    moc: NSManagedObjectContext
  ) throws -> ChapterPagesMO {
    if let local = try getChapterPages(for: chapterId, moc: moc) {
      updateEntity(
        local,
        baseUrl: baseUrl,
        chapterHash: chapterHash
      )

      return local
    } else {
      return try createEntity(
        baseUrl: baseUrl,
        chapterHash: chapterHash,
        chapter: chapter,
        moc: moc
      )
    }
  }

  func createEntity(
    baseUrl: String,
    chapterHash: String,
    chapter: ChapterMO,
    moc: NSManagedObjectContext
  ) throws -> ChapterPagesMO {
    guard let chapterPages = ChapterPagesMO(
      baseUrl: baseUrl,
      chapterHash: chapterHash,
      chapter: chapter,
      moc: moc
    ) else { throw CrudError.failedEntityCreation }

    return chapterPages
  }

  func updateEntity(
    _ chapterPages: ChapterPagesMO,
    baseUrl: String,
    chapterHash: String
  ) {
    chapterPages.baseUrl = baseUrl
    chapterPages.chapterHash = chapterHash
  }

  func updatePages(
    _ chapter: ChapterMO,
    pages: ChapterPagesMO?
  ) {
    chapter.pages = pages
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
