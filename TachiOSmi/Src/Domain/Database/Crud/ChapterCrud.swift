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

  func getChaptersPublished(
    before date: Date,
    count: Int,
    moc: NSManagedObjectContext
  ) throws -> [ChapterMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "publishAt < %@ AND manga.isSaved == true", date as NSDate)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "publishAt", ascending: false)]
    fetchRequest.fetchLimit = count

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getAllChapters(
    excludingIds ids: [String] = [],
    moc: NSManagedObjectContext
  ) throws -> [ChapterMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    if !ids.isEmpty {
      fetchRequest.predicate = NSPredicate(format: "NOT id IN %@", ids)
    }
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChapterMO.manga.id, ascending: true)]

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        throw CrudError.wrongRequestType
      }

      return results
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


  func getAllSavedMangaChapters(
    moc: NSManagedObjectContext
  ) throws -> [ChapterMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.isSaved == YES")

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        throw CrudError.wrongRequestType
      }

      return results
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getChaptersCount(
    for mangaId: String,
    read: Bool? = nil,
    moc: NSManagedObjectContext
  ) throws -> Int {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    let mangaPredicate = NSPredicate(format: "manga.id == %@", mangaId)

    if let read {
      let readPredicate = NSPredicate(format: "isRead == %@", NSNumber(value: read))

      fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mangaPredicate, readPredicate])
    } else {
      fetchRequest.predicate = mangaPredicate
    }

    do {
      return try moc.count(for: fetchRequest)
    } catch {
      throw CrudError.requestError(error)
    }
  }

  func getLatestChapterDate(
    mangaId: String,
    moc: NSManagedObjectContext
  ) throws -> Date? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.id == %@", mangaId)
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "publishAt", ascending: false)]
    fetchRequest.fetchLimit = 1

    do {
      guard let results = try moc.fetch(fetchRequest) as? [ChapterMO] else {
        throw CrudError.wrongRequestType
      }

      return results.first?.publishAt
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
    fetchRequest.sortDescriptors = [
      NSSortDescriptor(key: "chapter", ascending: true),
      NSSortDescriptor(key: "publishAt", ascending: true),
      NSSortDescriptor(key: "id", ascending: true),
    ]

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
    fetchRequest.sortDescriptors = [
      NSSortDescriptor(key: "chapter", ascending: true),
      NSSortDescriptor(key: "publishAt", ascending: true),
      NSSortDescriptor(key: "id", ascending: true)
    ]

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

  func didCreateOrUpdateChapter(
    id: String,
    chapterNumber: Double?,
    title: String?,
    numberOfPages: Int,
    publishAt: Date,
    urlInfo: String,
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) throws -> (Bool, ChapterMO) {
    if let local = try getChapter(id, moc: moc) {
      updateChapter(
        local,
        chapterNumber: chapterNumber,
        title: title,
        numberOfPages: numberOfPages,
        publishAt: publishAt,
        urlInfo: urlInfo
      )

      return (false, local)
    } else {
      let new = try createEntity(
        id: id,
        chapterNumber: chapterNumber,
        title: title,
        numberOfPages: numberOfPages,
        publishAt: publishAt,
        urlInfo: urlInfo,
        manga: manga,
        moc: moc
      )

      return (true, new)
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

    manga.chapters.insert(chapter)

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
    chapter.isRead = isRead
  }

  func updateLastPageRead(
    _ chapter: ChapterMO,
    lastPageRead: Int?
  ) {
    if let lastPageRead {
      chapter.lastPageRead = lastPageRead as NSNumber
    } else {
      chapter.lastPageRead = nil
    }
  }

}
