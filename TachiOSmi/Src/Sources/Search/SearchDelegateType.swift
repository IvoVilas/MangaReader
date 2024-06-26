//
//  SearchDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

protocol SearchDelegateType {

  var searchPageSize: Int { get }
  var trendingPageSize: Int { get }

  init(httpClient: HttpClientType)

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
