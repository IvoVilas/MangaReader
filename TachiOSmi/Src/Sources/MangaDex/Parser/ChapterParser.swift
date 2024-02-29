//
//  ChapterParser.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData
import UIKit

final class ChapterParser {

  private let dateFormatter: DateFormatter

  init() {
    dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
  }

  func parseChapterData(
    mangaId: String,
    data: [[String: Any]]
  ) -> [ChapterModel] {
    return data.compactMap {
      parseChapterData(mangaId: mangaId, data: $0)
    }
  }

  func parseChapterData(
    mangaId: String,
    data: [String: Any]
  ) -> ChapterModel? {
    var id: String?
    var number: Double?
    var title: String?
    var numberOfPages: Int?
    var publishAt: Date?

    // Get id
    id = data["id"] as? String

    // Get title, number and numberOfPages
    if let attributesJson = data["attributes"] as? [String: Any] {
      title         = attributesJson["title"] as? String
      numberOfPages = attributesJson["pages"] as? Int

      if let numberString = attributesJson["chapter"] as? String {
        number = Double(numberString)
      }

      if let date = attributesJson["publishAt"] as? String {
        publishAt = dateFormatter.date(from: date)
      }
    }

    guard
      let id,
      let numberOfPages,
      let publishAt
    else {
      print("ChapterParser Error -> Chapter parameter was not parsed")

      return nil
    }

    return ChapterModel(
      id: id,
      title: title,
      number: number,
      numberOfPages: numberOfPages,
      publishAt: publishAt
    )
  }

}
