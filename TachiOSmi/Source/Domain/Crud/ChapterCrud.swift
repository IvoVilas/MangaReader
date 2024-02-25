//
//  ChapterCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class ChapterCrud {

  func getChapter(
    withId id: String,
    moc: NSManagedObjectContext
  ) -> ChapterMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate  = NSPredicate(format: "id == %@", id)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [ChapterMO]

      return results?.first
    } catch {
      print("ChapterCrud Error -> Error during db request \(error)")
    }

    return nil
  }

  func getAllChapters(
    mangaId: String,
    moc: NSManagedObjectContext
  ) -> [ChapterMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.id == %@", mangaId)

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        print("ChapterCrud Error -> Error during db request")

        return []
      }

      return results
    } catch {
      print("ChapterCrud Error -> Error during db request \(error)")
    }

    return []
  }

  func createOrUpdateChapter(
    id: String,
    chapterNumber: Double?,
    title: String?,
    numberOfPages: Int,
    publishAt: Date,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) throws -> ChapterMO {
    if let local = getChapter(withId: id, moc: moc) {
      updateChapter(
        local,
        chapterNumber: chapterNumber,
        title: title,
        numberOfPages: numberOfPages,
        publishAt: publishAt
      )

      return local
    } else {
      return try createEntity(
        id: id,
        chapterNumber: chapterNumber,
        title: title,
        numberOfPages: numberOfPages,
        publishAt: publishAt,
        manga: manga,
        moc: moc
      )
    }
  }

  func createEntity(
    id: String,
    chapterNumber: Double?,
    title: String?,
    numberOfPages: Int,
    publishAt: Date,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) throws -> ChapterMO {
    guard let chapter = ChapterMO(
      id: id,
      chapter: chapterNumber,
      title: title,
      numberOfPages: Int16(numberOfPages),
      publishAt: publishAt,
      manga: manga,
      moc: moc
    ) else { throw CrudError.failedEntityCreation }

    return chapter
  }

  func updateChapter(
    _ chapter: ChapterMO,
    chapterNumber: Double?,
    title: String?,
    numberOfPages: Int,
    publishAt: Date
  ) {
    chapter.chapter       = chapterNumber as? NSNumber
    chapter.title         = title
    chapter.numberOfPages = Int16(numberOfPages)
    chapter.publishAt     = publishAt
  }

  func updatePages(
    _ chapter: ChapterMO,
    pages: ChapterPagesMO?
  ) {
    chapter.pages = pages
  }


}
