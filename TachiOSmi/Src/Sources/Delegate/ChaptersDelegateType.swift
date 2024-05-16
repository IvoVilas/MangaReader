//
//  ChaptersDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

protocol ChaptersDelegateType {

  init(httpClient: HttpClient)

  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterIndexResult]

}
