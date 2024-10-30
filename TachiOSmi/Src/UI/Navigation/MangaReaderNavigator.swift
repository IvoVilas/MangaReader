//
//  MangaReaderNavigator.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation

struct MangaReaderNavigator: Navigator {

  let source: Source
  let mangaId: String
  let mangaTitle: String
  let jumpToPage: String?
  let chapter: ChapterModel
  let readingDirection: ReadingDirection

  static func navigate(
    to entity: MangaReaderNavigator
  ) -> ChapterReaderView {
    return ChapterReaderView(
      source: entity.source,
      mangaId: entity.mangaId,
      mangaTitle: entity.mangaTitle,
      jumpToPage: entity.jumpToPage,
      chapter: entity.chapter,
      readingDirection: entity.readingDirection
    )
  }

}
