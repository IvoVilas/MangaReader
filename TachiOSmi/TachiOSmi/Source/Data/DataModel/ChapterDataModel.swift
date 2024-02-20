//
//  ChapterDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 19/02/2024.
//

import Foundation

struct ChapterModel: Identifiable, Hashable {

  let id: String
  let title: String?
  let number: Double?
  let numberOfPages: Int
  let publishAt: Date

  var description: String {
    let description: String

    guard let number else {
      return "Chapter N/A"
    }

    if number.truncatingRemainder(dividingBy: 1) == 0 {
      description = String(format: "%.0f", number)
    } else {
      description = String(format: "%.2f", number).trimmingCharacters(in: ["0"])
    }

    return "Chapter \(description)"
  }

  // DateFormatter and Calendar operations are heavy, one should not be created everytime this is called
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

    if let number = chapter.chapter {
      chapterNumber = Double(truncating: number)
    }

    return ChapterModel(
      id: chapter.id,
      title: chapter.title,
      number: chapterNumber,
      numberOfPages: Int(chapter.numberOfPages),
      publishAt: chapter.publishAt
    )
  }

}
