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
    _ id: String,
    moc: NSManagedObjectContext
  ) throws -> ChapterMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate  = NSPredicate(format: "id == %@", id)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [ChapterMO]

      return results?.first
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllChapters(
    mangaId: String,
    moc: NSManagedObjectContext
  ) throws -> [ChapterMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.id == %@", mangaId)

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func findNextChapter(
    _ id: String,
    mangaId: String,
    moc: NSManagedObjectContext
  ) throws -> ChapterMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.id == %@", mangaId)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "chapter", ascending: true)]

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        throw CrudError.wrongRequestType
      }

      if let index = results.firstIndex(where: { $0.id == id }) {
        return results.safeGet(index + 1)
      }

      return nil
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func findPreviousChapter(
    _ id: String,
    mangaId: String,
    moc: NSManagedObjectContext
  ) throws -> ChapterMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.id == %@", mangaId)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "chapter", ascending: true)]

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        throw CrudError.wrongRequestType
      }

      if let index = results.firstIndex(where: { $0.id == id }) {
        return results.safeGet(index - 1)
      }

      return nil
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func createOrUpdateChapter(
    id: String,
    chapterNumber: Double?,
    title: String?,
    numberOfPages: Int,
    publishAt: Date,
    urlInfo: String,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) throws -> ChapterMO {
    if let local = try getChapter(id, moc: moc) {
      updateChapter(
        local,
        chapterNumber: chapterNumber,
        title: title,
        numberOfPages: numberOfPages,
        publishAt: publishAt,
        urlInfo: urlInfo
      )

      return local
    } else {
      return try createEntity(
        id: id,
        chapterNumber: chapterNumber,
        title: title,
        numberOfPages: numberOfPages,
        publishAt: publishAt,
        urlInfo: urlInfo,
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
    urlInfo: String,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) throws -> ChapterMO {
    guard let chapter = ChapterMO(
      id: id,
      chapter: chapterNumber,
      title: title,
      numberOfPages: Int16(numberOfPages),
      publishAt: publishAt,
      urlInfo: urlInfo,
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
    publishAt: Date,
    urlInfo: String
  ) {
    chapter.chapter       = chapterNumber as? NSNumber
    chapter.title         = title
    chapter.numberOfPages = Int16(numberOfPages)
    chapter.publishAt     = publishAt
    chapter.urlInfo       = urlInfo
  }

  func updateIsRead(
    _ chapter: ChapterMO,
    isRead: Bool
  ) {
    if isRead {
      chapter.isRead = isRead
    }
  }

  func updateLastPageRead(
    _ chapter: ChapterMO,
    lastPageRead: Int?
  ) {
    guard let lastPageRead else { return }

    chapter.lastPageRead = lastPageRead as NSNumber
  }

}
