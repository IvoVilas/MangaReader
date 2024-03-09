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
  let status: MangaStatus
  let readingDirection: ReadingDirection
  let cover: Data?
  let tags: [TagModel]
  let authors: [AuthorModel]

  static func from(_ manga: MangaMO) -> MangaModel {
    return MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.synopsis,
      isSaved: manga.isSaved,
      status: .safeInit(from: manga.statusId),
      readingDirection: .safeInit(from: manga.readingDirection),
      cover: nil,
      tags: manga.tags.map { .from($0) }.sorted { $0.title < $1.title },
      authors: manga.authors.map { .from($0) }
    )
  }

  static func from(
    _ manga: MangaMO,
    cover: Data?
  ) -> MangaModel {
    return MangaModel(
      id: manga.id,
      title: manga.title,
      description: manga.synopsis,
      isSaved: manga.isSaved,
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
  let isSaved: Bool

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
    isSaved: Bool = false,
    readingDirection: ReadingDirection = .leftToRight,
    cover: Data? = nil
  ) -> MangaModel {
    return MangaModel(
      id: id,
      title: title,
      description: description,
      isSaved: isSaved,
      status: status,
      readingDirection: readingDirection,
      cover: cover,
      tags: tags.sorted { $0.title < $1.title },
      authors: authors
    )
  }

}
