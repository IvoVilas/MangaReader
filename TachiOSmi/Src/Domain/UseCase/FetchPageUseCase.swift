//
//  FetchPageUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 24/10/2024.
//

import Foundation
import CoreData

final class FetchPageUseCase {

  private let fileManager: LocalFileManager
  private let httpClient: HttpClientType
  private let crud: PageCrud

  init(
    fileManager: LocalFileManager,
    httpClient: HttpClientType,
    crud: PageCrud
  ) {
    self.fileManager = fileManager
    self.httpClient = httpClient
    self.crud = crud
  }

  func fetchPageModel(
    storedPage: StoredPageModel
  ) -> StoredPageModel? {
    var data: Data?

    if let filePath = storedPage.filePath {
      data = fileManager.loadImage(withName: filePath)
    }

    return storedPage.injectData(data)
  }

}
