//
//  MarkPageAsFavoriteUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 24/10/2024.
//

import Foundation
import CoreData

final class MarkPageAsFavoriteUseCase {

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

  func markPageAsFavorite(
    data: Data,
    pageId: String,
    mangaId: String,
    chapterId: String,
    pageNumber: Int,
    pageUrl: String,
    sourceId: String
  ) async -> EmptyResult<CrudError> {
    let context = container.newBackgroundContext()
    let fileName = UUID().uuidString

    _ = fileManager.saveImage(data, withName: fileName)

    do {
      try await context.perform { [weak self] in
        guard let self else { return }

        _ = self.crud.createOrUpdatePage(
          pageId: pageId,
          mangaId: mangaId,
          chapterId: chapterId,
          pageNumber: pageNumber,
          sourceId: sourceId,
          isFavorite: true,
          downloadInfo: pageUrl,
          filePath: fileName,
          moc: context
        )

        _ = try context.saveIfNeeded()
      }
    } catch {
      return .failure(.saveError)
    }

    return .success
  }

  func unmarkPageAsFavorite(
    _ pageId: String
  ) async {
    let context = container.newBackgroundContext()
    let fileName = UUID().uuidString

    let filename = try? await context.perform { [weak self] () -> String? in
      guard 
        let self,
        let storedPage = self.crud.getPage(pageId, moc: context)
      else {
        return nil
      }

      let filePath = storedPage.filePath

      context.delete(storedPage)

      _ = try context.saveIfNeeded()

      return filePath
    }

    if let filename {
      _ = fileManager.deleteImage(withName: fileName)
    }
  }

}

extension MarkPageAsFavoriteUseCase {


}
