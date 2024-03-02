//
//  PagesDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation

protocol PagesDelegateType {

  associatedtype Info: ChapterDownloadInfo

  init(httpClient: HttpClient)

  func fetchDownloadInfo(
    chapterId: String
  ) async throws -> Info

  func fetchPage(
    index: Int,
    info: Info
  ) async throws -> Data

  func fetchPage(
    _ url: String
  ) async throws -> Data

  func buildUrl(
    index: Int,
    info: Info
  ) throws -> String

}
