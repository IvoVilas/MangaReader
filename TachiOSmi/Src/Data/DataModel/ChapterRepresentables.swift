//
//  ChapterRepresentables.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 02/03/2024.
//

import Foundation

// MARK: Model
struct ChapterModel: Identifiable, Hashable {

  let id: String
  let title: String?
  let number: Double?
  let numberOfPages: Int
  let publishAt: Date
  let isRead: Bool
  let lastPageRead: Int?
  let downloadInfo: String

  var description: String {
    let identifier: String

    if let number {
      if number.truncatingRemainder(dividingBy: 1) == 0 {
        identifier = String(format: "%.0f", number)
      } else {
        identifier = String(format: "%.2f", number).trimmingCharacters(in: ["0"])
      }
    } else {
      identifier = "N/A"
    }

    if let title, !title.isEmpty {
      return "Chapter \(identifier) - \(title)"
    } else {
      return "Chapter \(identifier)"
    }
  }

  var lastPageReadDescription: String? {
    if let lastPageRead {
      return "Page: \(lastPageRead + 1)"
    }

    return nil
  }

  // TODO: DateFormatter and Calendar operations are heavy, one should not be created everytime this is called
  var createdAtDescription: String {
    let calendar = Calendar.current

    let today = calendar.dateComponents([.year, .month, .day], from: Date())
    let date  = calendar.dateComponents([.year, .month, .day], from: publishAt)

    if
      date.year == today.year,
      date.month == today.month,
      date.day == today.day
    {
      return "Today"
    }

    if
      let day = today.day,
      date.year == today.year,
      date.month == today.month,
      date.day == day + 1
    {
      return "Yesterday"
    }

    if
      let todayDay = today.day,
      let dateDay = date.day,
      date.year == today.year,
      date.month == today.month,
      todayDay <= dateDay + 7
    {
      return "\(todayDay - dateDay) days ago"
    }

    let formatter = DateFormatter()

    formatter.dateStyle = .medium
    formatter.timeStyle = .none

    return formatter.string(from: publishAt)
  }

  static func from(_ chapter: ChapterMO) -> ChapterModel {
    var chapterNumber: Double?
    var page: Int?

    if let number = chapter.chapter {
      chapterNumber = Double(truncating: number)
    }

    if let lastPageRead = chapter.lastPageRead {
      page = Int(truncating: lastPageRead)
    }

    return ChapterModel(
      id: chapter.id,
      title: chapter.title,
      number: chapterNumber,
      numberOfPages: Int(chapter.numberOfPages),
      publishAt: chapter.publishAt,
      isRead: chapter.isRead,
      lastPageRead: page,
      downloadInfo: chapter.urlInfo
    )
  }

}

// MARK: Index
struct ChapterIndexResult: Identifiable {

  let id: String
  let title: String?
  let number: Double?
  let numberOfPages: Int
  let publishAt: Date
  let downloadInfo: String

  func converToModel(
  ) -> ChapterModel {
    return ChapterModel(
      id: id,
      title: title, 
      number: number,
      numberOfPages: numberOfPages,
      publishAt: publishAt,
      isRead: false,
      lastPageRead: nil,
      downloadInfo: downloadInfo
    )
  }

}

// MARK: Download
struct ChapterDownloadInfo: Identifiable {

  let downloadUrl: String
  let pages: [String]

  var id: String { downloadUrl }

}
