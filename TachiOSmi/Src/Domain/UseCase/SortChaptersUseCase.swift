//
//  SortChaptersUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 04/04/2024.
//

import Foundation

struct SortChaptersUseCase {
  
  func sortByNumber(
    _ chapters: [ChapterModel]
  ) -> [ChapterModel] {
    let sortedChapters = chapters.sorted {
      guard let lhs = $0.number, let rhs = $1.number else {
        return $0.publishAt > $1.publishAt
      }

      return lhs > rhs
    }

    return sortedChapters
  }

}
