//
//  MangaParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData
import UIKit

final class MangaParser {

  struct MangaParsedData {
    let id: String
    let title: String
    let description: String?
    let status: MangaStatus
    let coverFileName: String

    func convertToModel(
      cover: UIImage? = nil
    ) -> MangaModel {
      return MangaModel(
        id: id,
        title: title,
        description: description,
        status: status,
        cover: cover,
        tags: []
      )
    }
  }

  func parseMangaSearchResponse(
    _ data: [[String: Any]]
  ) throws -> [MangaParsedData] {
    return try data.compactMap {
      try parseMangaSearchResponse($0)
    }
  }

  func parseMangaSearchResponse(
    _ data: [String: Any]
  ) throws -> MangaParsedData? {
    var id: String?
    var title: String?
    var description: String?
    var status: MangaStatus?
    var coverFileName: String?

    // Get id
    id = data["id"] as? String

    // Get title, description and status
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
    }

    // Get coverFileName
    if let relationships = data["relationships"] as? [[String: Any]] {
      for relationshipJson in relationships {
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

    return MangaParsedData(
      id: id,
      title: title,
      description: description,
      status: status,
      coverFileName: coverFileName
    )
  }

}

extension MangaParser {

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
