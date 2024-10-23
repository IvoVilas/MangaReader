//
//  SortChaptersUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 04/04/2024.
//

import Foundation

struct SortChaptersUseCase {
  
  func sortByNumber(
    _ chapters: [ChapterModel],
    ascending: Bool = false
  ) -> [ChapterModel] {
    let sortedChapters = chapters.sorted {
      return ascending == sortUsingNumber($0, $1)
    }

    return sortedChapters
  }

}

extension SortChaptersUseCase {

  private func sortUsingNumber(
    _ lhs: ChapterModel,
    _ rhs: ChapterModel
  ) -> Bool {
    guard
      let lhsNumber = lhs.number,
      let rhsNumber = rhs.number,
      lhsNumber != rhsNumber
    else {
      return sortUsingPublishAt(lhs, rhs)
    }

    return lhsNumber < rhsNumber
  }

  private func sortUsingPublishAt(
    _ lhs: ChapterModel,
    _ rhs: ChapterModel
  ) -> Bool {
    if lhs.publishAt == rhs.publishAt {
      return sortUsingId(lhs, rhs)
    }

    return lhs.publishAt < rhs.publishAt
  }

  private func sortUsingId(
    _ lhs: ChapterModel,
    _ rhs: ChapterModel
  ) -> Bool {
    return lhs.id < rhs.id
  }

}
