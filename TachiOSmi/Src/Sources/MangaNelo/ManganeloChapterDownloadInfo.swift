//
//  ManganeloChapterDownloadInfo.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 02/03/2024.
//

import Foundation

struct ManganeloChapterDownloadInfo: ChapterDownloadInfo {

  let chapterUrl: String
  let pages: [String]

  var id: String { "\(chapterUrl)" }

  var numberOfPages: Int { pages.count }

  init(
    chapterUrl: String,
    pages: [String]
  ) {
    self.chapterUrl = chapterUrl
    self.pages = pages
  }

}
