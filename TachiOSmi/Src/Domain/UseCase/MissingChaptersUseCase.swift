//
//  MissingChaptersUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 04/04/2024.
//

import Foundation

struct MissingChaptersUseCase {

  func calculateMissingChapters(
    _ chapters: [ChapterModel]
  ) -> [MissingChaptersModel] {
    guard !chapters.isEmpty else {
      return []
    }

    let numbers = chapters
      .compactMap { $0.number }
      .map { Int($0) }

    // Last = numbers.first becase sort order is inversed
    guard let last = numbers.first else {
      return []
    }

    var missing = [Int]()
    let chaptersNumbers = Set(numbers)

    for n in 1..<Int(last) {
      if !chaptersNumbers.contains(n) {
        missing.append(n)
      }
    }

    return mergeMissing(missing)
  }

}

extension MissingChaptersUseCase {

  private func mergeMissing(
    _ missing: [Int]
  ) -> [MissingChaptersModel] {
    var res = [MissingChaptersModel]()
    var lastMissing: Int?
    var group = [Int]()

    for m in missing {
      guard let last = lastMissing else {
        lastMissing = m
        group.append(m)

        continue
      }

      if m == last + 1 {
        group.append(m)
      } else {
        if let number = group.first {
          res.append(
            MissingChaptersModel(number: Double(number), count: group.count)
          )
        }

        group = [m]
      }

      lastMissing = m
    }

    if let number = group.first {
      res.append(
        MissingChaptersModel(number: Double(number), count: group.count)
      )
    }

    return res
  }

}
