//
//  DetailsDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import CoreData

protocol DetailsDelegateType {

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaParsedData

  func fetchCover(
    mangaId: String,
    fileName: String
  ) async throws -> Data

  func catchError(
    _ error: Error
  ) -> DatasourceError?

}
