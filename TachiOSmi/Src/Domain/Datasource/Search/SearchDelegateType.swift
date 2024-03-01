//
//  SearchDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

protocol SearchDelegateType {

  func fetchTrending(
    page: Int
  ) async throws -> [MangaParsedData]

  func fetchSearchResults(
    _ searchValue: String,
    page: Int
  ) async throws -> [MangaParsedData]

  func fetchCover(
    id: String,
    fileName: String
  ) async throws -> Data

  func catchError(
    _ error: Error
  ) -> DatasourceError?

}
