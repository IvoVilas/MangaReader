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

  struct MangaModelWrapper {
    let manga: MangaModel
    let coverFileName: String
  }

  private let mangaCrud: MangaCrud
  private let authorCrud: AuthorCrud
  private let tagCrud: TagCrud

  private let moc: NSManagedObjectContext

  init(
    mangaCrud: MangaCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    moc: NSManagedObjectContext
  ) {
    self.mangaCrud  = mangaCrud
    self.authorCrud = authorCrud
    self.tagCrud    = tagCrud
    self.moc        = moc
  }

  func parseMangaSearchResponse(
    _ data: [[String: Any]]
  ) -> [MangaModelWrapper] {
    return data.compactMap {
      parseMangaSearchResponse($0)
    }
  }

  func parseMangaSearchResponse(
    _ data: [String: Any]
  ) -> MangaModelWrapper? {
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

    guard let manga = mangaCrud.createOrUpdateManga(
      id: id,
      title: title,
      about: description,
      status: status,
      moc: moc
    ) else {
      print("MangaParser Error -> Entity creation failed")

      return nil
    }

    return MangaModelWrapper(
      manga: MangaModel.from(manga),
      coverFileName: coverFileName
    )
  }

  func handleMangaCoverResponse(
    _ id: String,
    data: Data?
  ) -> MangaModel? {
    guard let manga = mangaCrud.getManga(withId: id, moc: moc) else {
      print("MangaParser Error -> Manga with id:\(id) not found")

      return nil
    }

    guard let data else {
      return MangaModel.from(
        manga,
        coverData: nil
      )
    }

    mangaCrud.updateCoverArt(manga, data: data)

    _ = moc.saveIfNeeded(rollbackOnError: true)

    return MangaModel.from(
      manga,
      coverData: data
    )
  }

}
