//
//  MangaReaderNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation
import CoreData

struct MangaReaderNavigator: Navigator {

  let source: Source
  let mangaId: String
  let mangaTitle: String
  let chapter: ChapterModel
  let readingDirection: ReadingDirection

  static func navigate(
    to entity: MangaReaderNavigator
  ) -> ChapterReaderView {
    return ChapterReaderView(
      source: entity.source,
      mangaId: entity.mangaId,
      mangaTitle: entity.mangaTitle,
      chapter: entity.chapter,
      readingDirection: entity.readingDirection
    )
  }

}
