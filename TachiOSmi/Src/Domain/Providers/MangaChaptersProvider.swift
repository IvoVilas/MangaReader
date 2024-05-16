//
//  MangaChaptersProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import CoreData
import SwiftUI

final class MangaChaptersProvider: NSObject, ObservableObject {

  @Published var chapters = [ChapterModel]()

  private let fetchedResultsController: NSFetchedResultsController<ChapterMO>

  init(
    mangaId: String,
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<ChapterMO>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.id == %@", mangaId)
    fetchRequest.sortDescriptors = [
      NSSortDescriptor(keyPath: \ChapterMO.chapter, ascending: false),
      NSSortDescriptor(keyPath: \ChapterMO.publishAt, ascending: false)
    ]

    self.fetchedResultsController = NSFetchedResultsController<ChapterMO>(
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

    chapters = (fetchedResultsController.fetchedObjects ?? [])
      .map { chapter in
        context.performAndWait {
          ChapterModel.from(chapter)
        }
      }
  }

}

extension MangaChaptersProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}
