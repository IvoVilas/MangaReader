//
//  ChapterPagesDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation

struct ChapterDownloadInfoModel: Identifiable {

  let baseUrl: String
  let hash: String
  let data: [String]

  var id: String { "\(baseUrl)_\(hash)" }

  var url: String { "\(baseUrl)/data/\(hash)" }

  init(
    baseUrl: String,
    hash: String,
    data: [String]
  ) {
    self.baseUrl = baseUrl
    self.hash    = hash
    self.data    = data
  }

}
