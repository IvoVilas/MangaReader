//
//  MissingChaptersUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 04/04/2024.
//

import Foundation

struct MissingChaptersUseCase {

  private struct ChapterNumber {
    let number: Int
    let isRead: Bool
  }

  func calculateMissingChapters(
    _ chapters: [ChapterModel]
  ) -> [MissingChaptersModel] {
    guard !chapters.isEmpty else {
      return []
    }

    let chapters: [ChapterNumber] = chapters
      .compactMap { (chapter) -> (Double, Bool)? in
        guard let number = chapter.number else { return nil }

        return number.truncatingRemainder(dividingBy: 1.0) == .zero ? (number, chapter.isRead) : nil
      }
      .map {
        ChapterNumber(
          number: Int($0.0),
          isRead: $0.1
        )
      }

    // Last = numbers.first becase sort order is inversed
    guard 
      let last = chapters.first,
      let first = chapters.last,
      first.number <= last.number
    else {
      return []
    }


    var missing = [ChapterNumber]()
    var isPreviousRead = false

    for n in (first.number...last.number).reversed() {
      if let chapter = chapters.first(where: { $0.number == n }) {
        isPreviousRead = chapter.isRead
      } else {
        missing.append(
          ChapterNumber(
            number: n,
            isRead: isPreviousRead
          )
        )
      }
    }

    return mergeMissing(missing)
  }

}

extension MissingChaptersUseCase {

  private func mergeMissing(
    _ missing: [ChapterNumber]
  ) -> [MissingChaptersModel] {
    var res = [MissingChaptersModel]()
    var lastMissing: ChapterNumber?
    var group = [ChapterNumber]()

    for m in missing {
      guard let last = lastMissing else {
        lastMissing = m
        group.append(m)

        continue
      }

      if m.number == last.number + 1 {
        group.append(m)
      } else {
        if let chapterNumber = group.first {
          res.append(
            MissingChaptersModel(
              number: Double(chapterNumber.number),
              count: group.count,
              isRead: chapterNumber.isRead
            )
          )
        }

        group = [m]
      }

      lastMissing = m
    }

    if let chapterNumber = group.first {
      res.append(
        MissingChaptersModel(
          number: Double(chapterNumber.number),
          count: group.count,
          isRead: chapterNumber.isRead
        )
      )
    }

    return res
  }

}
