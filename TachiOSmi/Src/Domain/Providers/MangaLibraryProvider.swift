//
//  MangaLibraryProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import CoreData
import Combine

final class MangaLibraryProvider: NSObject {

  private let fetchedResultsController: NSFetchedResultsController<MangaMO>
  private let mangasPublisher: CurrentValueSubject<[MangaSearchResult], Never>

  var mangas: AnyPublisher<[MangaSearchResult], Never> {
    mangasPublisher.eraseToAnyPublisher()
  }

  private let coverCrud: CoverCrud

  init(
    coverCrud: CoverCrud,
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<MangaMO>(entityName: "Manga")

    fetchRequest.predicate = NSPredicate(format: "isSaved == true")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MangaMO.title, ascending: true)]

    self.coverCrud = coverCrud
    self.mangasPublisher = CurrentValueSubject([])
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

    mangasPublisher.value = (fetchedResultsController.fetchedObjects ?? [])
      .map { manga in
        context.performAndWait {
          let coverData = try? self.coverCrud.getCoverData(for: manga.id, moc: context)

          return MangaSearchResult(
            id: manga.id,
            title: manga.title,
            cover: coverData,
            source: .safeInit(from: manga.sourceId)
          )
        }
      }
  }

}

extension MangaLibraryProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}
