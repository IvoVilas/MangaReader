//
//  PagesDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation

protocol PagesDelegateType {

  init(httpClient: HttpClientType)

  func fetchDownloadInfo(
    using: String,
    saveData: Bool
  ) async throws -> ChapterDownloadInfo

  func fetchPage(
    index: Int,
    info: ChapterDownloadInfo
  ) async throws -> Data

  func fetchPage(
    url: String,
    info: ChapterDownloadInfo
  ) async throws -> Data

  func buildPageUrl(
    index: Int,
    info: ChapterDownloadInfo
  ) throws -> String

}
