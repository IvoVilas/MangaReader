//
//  MangaDetailsProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import Foundation
import CoreData
import SwiftUI

final class MangaDetailsProvider: NSObject, ObservableObject {

  @Published var details: MangaModel?

  private let fetchedResultsController: NSFetchedResultsController<MangaMO>
  private let coverCrud: CoverCrud

  init(
    mangaId: String,
    coverCrud: CoverCrud,
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<MangaMO>(entityName: "Manga")

    fetchRequest.predicate = NSPredicate(format: "id == %@", mangaId)
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MangaMO.id, ascending: true)]
    fetchRequest.fetchLimit = 1

    self.coverCrud = coverCrud
    self.fetchedResultsController = NSFetchedResultsController<MangaMO>(
      fetchRequest: fetchRequest,
      managedObjectContext: viewMoc,
      sectionNameKeyPath: nil,
      cacheName: nil
    )

    super.init()

    initializeFetchedResultsController()
  }

  private func initializeFetchedResultsController() {
    fetchedResultsController.delegate = self

    try? fetchedResultsController.performFetch()

    updatePublishedValue()
  }

  private func updatePublishedValue() {
    let context = self.fetchedResultsController.managedObjectContext

    details = fetchedResultsController
      .fetchedObjects?
      .first
      .map { manga in
        context.performAndWait {
          let cover = try? self.coverCrud.getCoverData(for: manga.id, moc: context)

          return MangaModel.from(manga, cover: cover)
        }
      }
  }

}

extension MangaDetailsProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}

