//
//  MangaParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData
import UIKit

struct MangaParser {

  func parseMangaSearchResponse(
    _ data: [[String: Any]]
  ) throws -> [MangaSearchResultParsedData] {
    return try data.compactMap {
      try parseMangaSearchResult($0)
    }
  }

  func parseMangaDetailsResponse(
    _ data: [String: Any]
  ) throws -> MangaDetailsParsedData {
    var id: String?
    var title: String?
    var description: String?
    var status: MangaStatus?
    var coverFileName: String?

    var tags = [TagModel]()
    var authors = [AuthorModel]()

    // Get id
    id = data["id"] as? String

    // Get title, description, status and tags
    if let attributesJson = data["attributes"] as? [String: Any] {
      if let titlesJson = attributesJson["title"] as? [String: Any] {
        title = getBestTitle(from: titlesJson)
      }

      if let descriptionsJson = attributesJson["description"] as? [String: Any] {
        description = descriptionsJson["en"] as? String
      }

      if let statusValue = attributesJson["status"] as? String {
        status = .safeInit(from: statusValue)
      }

      if let tagsJson = attributesJson["tags"] as? [[String: Any]] {
        tags = parseTags(from: tagsJson)
      }
    }

    // Get authors and coverFileName
    if let relationshipsJson = data["relationships"] as? [[String: Any]] {
      authors = parseAuthors(from: relationshipsJson)

      for relationshipJson in relationshipsJson {
        if relationshipJson["type"] as? String == "cover_art" {
          if let attributesJson = relationshipJson["attributes"] as? [String: Any] {
            coverFileName = attributesJson["fileName"] as? String

            break
          }
        }
      }
    }

    guard
      let id,
      let title,
      let status,
      let coverFileName
    else {
      if id == nil { throw ParserError.parameterNotFound("id") }
      if title == nil { throw ParserError.parameterNotFound("title") }
      if status == nil { throw ParserError.parameterNotFound("status") }
      if coverFileName == nil { throw ParserError.parameterNotFound("coverFileName") }

      throw ParserError.parsingError
    }

    return MangaDetailsParsedData(
      id: id,
      title: title,
      description: description,
      status: status,
      tags: tags,
      authors: authors,
      coverInfo: coverFileName
    )
  }

}

extension MangaParser {

  private func parseMangaSearchResult(
    _ data: [String: Any]
  ) throws -> MangaSearchResultParsedData {
    var id: String?
    var title: String?
    var coverFileName: String?

    // Get id
    id = data["id"] as? String

    // Get title, description, status and tags
    if let attributesJson = data["attributes"] as? [String: Any] {
      if let titlesJson = attributesJson["title"] as? [String: Any] {
        title = getBestTitle(from: titlesJson)
      }
    }

    // Get authors and coverFileName
    if let relationshipsJson = data["relationships"] as? [[String: Any]] {
      for relationshipJson in relationshipsJson {
        if relationshipJson["type"] as? String == "cover_art" {
          if let attributesJson = relationshipJson["attributes"] as? [String: Any] {
            coverFileName = attributesJson["fileName"] as? String

            break
          }
        }
      }
    }

    guard
      let id,
      let title,
      let coverFileName
    else {
      if id == nil { throw ParserError.parameterNotFound("id") }
      if title == nil { throw ParserError.parameterNotFound("title") }
      if coverFileName == nil { throw ParserError.parameterNotFound("coverFileName") }

      throw ParserError.parsingError
    }

    return MangaSearchResultParsedData(
      id: id,
      title: title,
      coverDownloadInfo: coverFileName
    )

  }

  private func parseTags(
    from tagsJson: [[String: Any]]
  ) -> [TagModel] {
    return tagsJson.compactMap { tagJson -> TagModel? in
      let id = tagJson["id"] as? String

      if let tagAttributes = tagJson["attributes"] as? [String: Any] {
        if let nameJson = tagAttributes["name"] as? [String: Any] {
          let title = getBestTitle(from: nameJson)

          guard
            let id,
            let title
          else {
            print("MangaParser -> Tag info missing") // Dont want to throw, only miss tag

            return nil
          }

          return TagModel(id: id, title: title)
        }
      }

      return nil
    }
  }

  private func parseAuthors(
    from relationshipsJson: [[String: Any]]
  ) -> [AuthorModel] {
    return relationshipsJson.compactMap { relationshipJson -> AuthorModel? in
      if relationshipJson["type"] as? String == "author" {
        let id = relationshipJson["id"] as? String

        if let attributesJson = relationshipJson["attributes"] as? [String: Any] {
          let name = attributesJson["name"] as? String

          guard
            let id,
            let name
          else {
            print("MangaParser -> Author info missing") // Dont want to throw, only miss author

            return nil
          }

          return AuthorModel(id: id, name: name)
        }
      }

      return nil
    }
  }

  private func getBestTitle(
    from titles: [String: Any]
  ) -> String? {
    let priorities = ["en", "ja-ro", "ko-ro", "zh-ro"]

    for language in priorities {
      if let title = titles[language] as? String {
        return title
      }
    }

    for value in titles.values {
      if let title = value as? String {
        return title
      }
    }

    return nil
  }

}
