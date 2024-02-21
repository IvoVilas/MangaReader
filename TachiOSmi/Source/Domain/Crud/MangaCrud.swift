//
//  MangaCrud.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

final class MangaCrud { }

// MARK: - Get
extension MangaCrud {

  func getManga(
    _ id: String,
    moc: NSManagedObjectContext
  ) -> MangaMO? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")

    fetchRequest.predicate  = NSPredicate(format: "id == %@", id)
    fetchRequest.fetchLimit = 1

    do {
      let results = try moc.fetch(fetchRequest) as? [MangaMO]

      return results?.first
    } catch {
      print("MangaCrud Error -> Error during db request \(error)")
    }

    return nil
  }

  func getAllMangas(
    moc: NSManagedObjectContext
  ) -> [MangaMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")

    do {
      guard let results = try moc.fetch(fetchRequest) as? [MangaMO] else {
        print("MangaCrud Error -> Error during db request")

        return []
      }

      return results
    } catch {
      print("MangaCrud Error -> Error during db request \(error)")
    }

    return []
  }

  func getAllMangasWithChapters(
    moc: NSManagedObjectContext
  ) -> [MangaMO] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")

    fetchRequest.predicate = NSPredicate(format: "%K.@count > 0", #keyPath(MangaMO.chapters))

    do {
      guard let results = try moc.fetch(fetchRequest) as? [MangaMO] else {
        print("MangaCrud Error -> Error during db request")

        return []
      }

      return results
    } catch {
      print("MangaCrud Error -> Error during db request \(error)")
    }

    return []
  }

  func getAllMangasIdsWithoutCovers(
    fromIds ids: [String] = [],
    moc: NSManagedObjectContext
  ) -> [String] {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Manga")
    let predicate: NSPredicate

    if ids.isEmpty {
      predicate = NSPredicate(format: "coverArt == nil")
    } else {
      predicate = NSPredicate(format: "coverArt == nil AND id IN %@", ids)
    }

    // TODO: Only get ids
    fetchRequest.predicate = predicate

    do {
      guard let results = try moc.fetch(fetchRequest) as? [MangaMO] else {
        print("MangaCrud Error -> Error during db request")

        return []
      }

      return results.map { $0.id }
    } catch {
      print("MangaCrud Error -> Error during db request \(error)")
    }

    return []
  }

}

// MARK: - Create or Update
extension MangaCrud {

  func createOrUpdateManga(
    id: String,
    title: String,
    about: String?,
    status: MangaStatus,
    moc: NSManagedObjectContext
  ) -> MangaMO? {
    var manga: MangaMO?

    if let local = getManga(id, moc: moc) {
      updateManga(
        local,
        title: title,
        about: about,
        status: status,
        moc: moc
      )

      manga = local
    } else {
      manga = createEntity(
        id: id,
        title: title,
        about: about,
        status: status,
        moc: moc
      )
    }

    if moc.saveIfNeeded(rollbackOnError: true).isSuccess {
      return manga
    }

    return nil
  }

}

// MARK: - Create
extension MangaCrud {

  func createEntity(
    id: String,
    title: String,
    about: String?,
    status: MangaStatus,
    moc: NSManagedObjectContext
  ) -> MangaMO? {
    let manga = MangaMO(
      id: id,
      title: title,
      about: about,
      statusId: status.id,
      lastUpdateAt: nil,
      coverArt: nil,
      moc: moc
    )

    if moc.saveIfNeeded(rollbackOnError: true).isSuccess {
      return manga
    }

    return nil
  }

}

// MARK: - Update
extension MangaCrud {

  func updateManga(
    _ manga: MangaMO,
    title: String,
    about: String?,
    status: MangaStatus,
    moc: NSManagedObjectContext
  ) {
    manga.title    = title
    manga.about    = about
    manga.statusId = status.id
  }

  func updateCoverArt(
    _ manga: MangaMO,
    data: Data?
  ) {
    manga.coverArt = data
  }

  func updateLastUpdateAt(
    _ manga: MangaMO,
    date: Date?
  ) {
    manga.lastUpdateAt = date
  }

  func updateLastUpdateAt(
    _ id: String,
    date: Date?,
    moc: NSManagedObjectContext
  ) {
    guard let manga = getManga(id, moc: moc) else {
      print("MangaCrud Error -> Manga not found \(id)")

      return
    }

    manga.lastUpdateAt = date

    _ = moc.saveIfNeeded(rollbackOnError: true)
  }

  func addTag(
    _ manga: MangaMO,
    tag: TagMO
  ) {
    manga.tags.insert(tag)
  }

  func addTags(
    _ manga: MangaMO,
    tags: Set<TagMO>
  ) {
    for tag in tags {
      manga.tags.insert(tag)
    }
  }

  func addAuthor(
    _ manga: MangaMO,
    author: AuthorMO
  ) {
    manga.authors.insert(author)
  }

  func addAuthors(
    _ manga: MangaMO,
    authors: [AuthorMO]
  ) {
    for author in authors {
      manga.authors.insert(author)
    }
  }

}
