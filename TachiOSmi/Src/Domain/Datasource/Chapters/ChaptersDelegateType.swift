//
//  ChaptersDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

protocol ChaptersDelegateType {

  func fetchChapters(
    mangaId: String
  ) async throws -> [ChapterModel]

  func catchError(
    _ error: Error
  ) -> DatasourceError?

}
