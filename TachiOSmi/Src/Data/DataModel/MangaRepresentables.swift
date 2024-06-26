//
//  MangaRepresentables.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 02/03/2024.
//

import Foundation

// MARK: Model
struct MangaModel: Identifiable, Hashable {

  let id: String
  let title: String
  let description: String?
  let isSaved: Bool
  let source: Source
  let status: MangaStatus
  let readingDirection: ReadingDirection
  let cover: Data?
  let tags: [TagModel]
  let authors: [AuthorModel]

  static func from(
    _ manga: MangaMO,
    cover: Data? = nil
  ) -> MangaModel {
    return MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.synopsis,
      isSaved: manga.isSaved, 
      source: .safeInit(from: manga.sourceId),
      status: .safeInit(from: manga.statusId),
      readingDirection: .safeInit(from: manga.readingDirection),
      cover: cover,
      tags: manga.tags.map { .from($0) }.sorted { $0.title < $1.title },
      authors: manga.authors.map { .from($0) }
    )
  }

}

// MARK: Search
struct MangaSearchResultParsedData: Identifiable, Hashable {

  let id: String
  let title: String
  let coverDownloadInfo: String

}

struct MangaSearchResult: Identifiable, Hashable {

  let id: String
  let title: String
  let cover: Data?
  let source: Source

}

// MARK: Details
struct MangaDetailsParsedData {

  let id: String
  let title: String
  let description: String?
  let status: MangaStatus
  let tags: [TagModel]
  let authors: [AuthorModel]
  let coverInfo: String

  func convertToModel(
    source: Source,
    isSaved: Bool = false,
    readingDirection: ReadingDirection = .leftToRight,
    cover: Data? = nil
  ) -> MangaModel {
    return MangaModel(
      id: id,
      title: title,
      description: description,
      isSaved: isSaved,
      source: source,
      status: status,
      readingDirection: readingDirection,
      cover: cover,
      tags: tags.sorted { $0.title < $1.title },
      authors: authors
    )
  }

}

// MARK: Refresh
struct MangaRefreshData {

  let id: String
  let title: String
  let description: String?
  let cover: Data?
  let status: MangaStatus
  let tags: [TagModel]
  let authors: [AuthorModel]
  let chapters: [ChapterIndexResult]

  init(
    id: String,
    title: String,
    description: String?,
    cover: Data?,
    status: MangaStatus,
    tags: [TagModel],
    authors: [AuthorModel], 
    chapters: [ChapterIndexResult]
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.cover = cover
    self.status = status
    self.tags = tags
    self.authors = authors
    self.chapters = chapters
  }

  init(
    id: String,
    cover: Data?,
    details: MangaDetailsParsedData,
    chapters: [ChapterIndexResult]
  ) {
    self.id = id
    self.title = details.title
    self.description = details.description
    self.cover = cover
    self.status = details.status
    self.tags = details.tags
    self.authors = details.authors
    self.chapters = chapters
  }

}
