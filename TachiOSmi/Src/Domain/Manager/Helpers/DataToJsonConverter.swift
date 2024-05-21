//
//  DataToJsonConverter.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 19/05/2024.
//

import Foundation

struct DataToJsonConverter {

  let formatter: Formatter

  func convert(_ manga: MangaMO) -> [String: Any] {
    var res = [String: Any]()

    res["id"] = manga.id
    res["title"] = manga.title
    res["synopsis"] = manga.synopsis
    res["status_id"] = manga.statusId
    res["is_saved"] = manga.isSaved
    res["reading_direction"] = manga.readingDirection
    res["source_id"] = manga.sourceId

    if let lastUpdateAt = manga.lastUpdateAt {
      res["last_update_at"] = formatter.dateAsISO8601(lastUpdateAt)
    } else {
      res["last_update_at"] = nil
    }

    return res
  }

  func convert(_ chapter: ChapterMO) -> [String: Any] {
    var res = [String: Any]()

    res["id"] = chapter.id
    res["manga_id"] = chapter.manga.id
    res["chapter"] = chapter.chapter
    res["title"] = chapter.title
    res["number_of_pages"] = chapter.numberOfPages
    res["publish_at"] = formatter.dateAsISO8601(chapter.publishAt)
    res["url_info"] = chapter.urlInfo
    res["is_read"] = chapter.isRead
    res["last_page_read"] = chapter.lastPageRead

    return res
  }

  func convert(_ author: AuthorMO) -> [String: Any] {
    var res = [String: Any]()

    res["id"] = author.id
    res["name"] = author.name
    res["mangas_id"] = author.mangas.map { $0.id }

    return res
  }

  func convert(_ tag: TagMO) -> [String: Any] {
    var res = [String: Any]()

    res["id"] = tag.id
    res["title"] = tag.title

    return res
  }

  func convert(_ cover: CoverMO) -> [String: Any] {
    var res = [String: Any]()

    res["manga_id"] = cover.mangaId
    res["data"] = cover.data

    return res
  }

}
