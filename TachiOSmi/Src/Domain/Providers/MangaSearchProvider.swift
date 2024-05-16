//
//  MangaSearchProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import CoreData
import SwiftUI

final class MangaSearchProvider: NSObject, ObservableObject {

  @Published var savedMangas = [String]()

  private let fetchedResultsController: NSFetchedResultsController<MangaMO>

  init(
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<MangaMO>(entityName: "Manga")

    fetchRequest.predicate = NSPredicate(format: "isSaved == true")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MangaMO.id, ascending: true)]

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

    savedMangas = (fetchedResultsController.fetchedObjects ?? [])
      .map { manga in
        context.performAndWait { manga.id }
      }
  }

}

extension MangaSearchProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}
