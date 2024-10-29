//
//  SavePageUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 24/10/2024.
//

import Foundation
import CoreData

final class SavePageUseCase {

  private let fileManager: LocalFileManager
  private let crud: PageCrud
  private let container: NSPersistentContainer

  init(
    fileManager: LocalFileManager,
    crud: PageCrud,
    container: NSPersistentContainer
  ) {
    self.fileManager = fileManager
    self.crud        = crud
    self.container   = container
  }

  func savePage(
    data: Data,
    pageUrl: String,
    mangaId: String,
    sourceId: String,
    isFavorite: Bool
  ) async throws {
    let context = container.newBackgroundContext()

    // TODO: Change this
    let name = UUID().uuidString

    _ = fileManager.saveImage(data, withName: name)

    try await context.perform { [weak self, weak context] in
      guard let self, let context else { return }

      _ = try self.crud.createOrUpdatePage(
        id: pageUrl,
        mangaId: mangaId,
        sourceId: sourceId,
        isFavorite: isFavorite,
        downloadInfo: pageUrl,
        filePath: name,
        moc: context
      )

      _ = try context.saveIfNeeded()
    }
  }

}

