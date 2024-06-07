//
//  RefreshDelegateType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation

protocol RefreshDelegateType {

  init(httpClient: HttpClientType)

  func fetchRefreshData(
    _ mangaId: String,
    updateCover: Bool
  ) async throws -> MangaRefreshData

}
