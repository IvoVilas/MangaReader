//
//  ManganeloDetailsDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import Foundation
import SwiftSoup
import Alamofire

final class ManganeloDetailsDelegate: DetailsDelegateType {

  init(
    httpClient: HttpClient,
    mangaParser: MangaParser
  ) {
    
  }
  

  func fetchDetails(
    _ mangaId: String
  ) async throws -> MangaParsedData {
    throw DatasourceError.otherError("TODO")
  }
  
  func fetchCover(
    mangaId: String, fileName: String
  ) async throws -> Data {
    throw DatasourceError.otherError("TODO")
  }
  
}
