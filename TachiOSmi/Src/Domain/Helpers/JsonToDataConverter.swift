//
//  JsonToDataConverter.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 20/05/2024.
//

import Foundation
import CoreData

struct JsonToDataConverter {

  let mangaCrud: MangaCrud
  let chapterCrud: ChapterCrud
  let authorCrud: AuthorCrud
  let tagCrud: TagCrud
  let formatter: Formatter

  func toManga(
    _ json: [String: Any],
    moc: NSManagedObjectContext
  ) -> MangaMO? {
    guard
      let id = json["id"] as? String,
      let title = json["title"] as? String,
      let statusId = json["status_id"] as? Int16,
      let isSaved = json["is_saved"] as? Bool,
      let readingDirection = json["reading_direction"] as? Int16,
      let sourceId = json["source_id"] as? String,
      let chapters = json["chapters"] as? [[String: Any]],
      let authors = json["authors"] as? [[String: Any]],
      let tags = json["tags"] as? [[String: Any]],
      let manga = try? mangaCrud.createOrUpdateManga(
        id: id,
        title: title,
        synopsis: json["synopsis"] as? String,
        isSaved: isSaved,
        status: .safeInit(from: statusId),
        source: .safeInit(from: sourceId),
        readingDirection: .safeInit(from: readingDirection),
        moc: moc
      )
    else {
      return nil
    }

    _ = chapters.compactMap { toChapter($0, manga: manga, moc: moc) }
    _ = authors.compactMap { toAuthor($0, manga: manga, moc: moc) }
    _ = tags.compactMap { toTag($0, manga: manga, moc: moc) }

    return manga
  }

  func toChapter(
    _ json: [String: Any],
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) -> ChapterMO? {
    guard
      let mangaId = json["manga_id"] as? String,
      manga.id == mangaId,

      let id = json["id"] as? String,
      let numberOfPages = json["number_of_pages"] as? Int,
      let publishAt = json["publish_at"] as? String,
      let publishAt = formatter.dateFromISO8601(publishAt),
      let urlInfo = json["url_info"] as? String,
      // let isRead = json["is_read"] as? Bool,
      let chapter = try? chapterCrud.createOrUpdateChapter(
        id: id,
        chapterNumber: json["chapter"] as? Double,
        title: json["title"] as? String,
        numberOfPages: numberOfPages,
        publishAt: publishAt,
        urlInfo: urlInfo,
        manga: manga,
        moc: moc
      )
    else {
      return nil
    }

    manga.chapters.insert(chapter)

    return chapter
  }

  func toAuthor(
    _ json: [String: Any],
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) -> AuthorMO? {
    guard
      let id = json["id"] as? String,
      let name = json["name"] as? String,
      let author = try? authorCrud.createOrUpdateAuthor(
        id: id,
        name: name,
        manga: manga,
        moc: moc
      )
    else {
      return nil
    }

    authorCrud.addManga(author, manga: manga)

    return author
  }

  func toTag(
    _ json: [String: Any],
    manga: MangaMO,
    moc: NSManagedObjectContext
  ) -> TagMO? {
    guard
      let id = json["id"] as? String,
      let title = json["title"] as? String,
      let tag = try? tagCrud.createOrUpdateTag(
        id: id,
        title: title,
        manga: manga,
        moc: moc
      )
    else {
      return nil
    }

    tagCrud.addManga(tag, manga: manga)

    return tag
  }

}
