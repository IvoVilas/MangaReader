//
//  MangadexChapterDowloadInfo.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

struct MangadexChapterDownloadInfo: ChapterDownloadInfo {

  let baseUrl: String
  let hash: String
  let pages: [String]

  var id: String { "\(baseUrl)_\(hash)" }
  var url: String { "\(baseUrl)/data/\(hash)" }
  var numberOfPages: Int { pages.count }

  init(
    baseUrl: String,
    hash: String,
    pages: [String]
  ) {
    self.baseUrl = baseUrl
    self.hash = hash
    self.pages = pages
  }

}
