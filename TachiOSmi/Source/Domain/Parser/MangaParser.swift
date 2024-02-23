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
  ) -> [MangaParsedData] {
    return data.compactMap {
      parseMangaSearchResponse($0)
    }
  }

  func parseMangaSearchResponse(
    _ data: [String: Any]
  ) -> MangaParsedData? {
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
        title = titlesJson["en"] as? String
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
      print("MangaParser Error -> Manga parameter was not parsed")

      return nil
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
