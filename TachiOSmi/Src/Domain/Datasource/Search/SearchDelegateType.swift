//
//  SearchDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

protocol SearchDelegateType {

  init(
    httpClient: HttpClient,
    mangaParser: MangaParser
  )

  func fetchTrending(
    page: Int
  ) async throws -> [MangaSearchResultParsedData]

  func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaSearchResultParsedData]

  func fetchCover(
    mangaId: String,
    coverInfo: String
  ) async throws -> Data

}
