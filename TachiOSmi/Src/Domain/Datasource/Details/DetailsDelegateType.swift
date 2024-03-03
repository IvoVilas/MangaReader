//
//  DetailsDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

protocol DetailsDelegateType {

  init(
    httpClient: HttpClient,
    mangaParser: MangaParser
  )

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaDetailsParsedData

  func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data

}
