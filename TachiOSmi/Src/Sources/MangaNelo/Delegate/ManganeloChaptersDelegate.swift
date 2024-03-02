//
//  ManganeloChaptersDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation

final class ManganeloChaptersDelegate: ChaptersDelegateType {

  init(
    httpClient: HttpClient,
    chapterParser: ChapterParser,
    systemDateTime: SystemDateTimeType
  ) {

  }

  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterModel] {
    throw DatasourceError.otherError("TODO")
  }

}
