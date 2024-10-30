//
//  MangaFavoritePagesProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 29/10/2024.
//

import Foundation
import Combine
import CoreData

final class MangaFavoritePagesProvider: NSObject {

  struct MangaPage {
    let id: String
  }

  private let fetchedResultsController: NSFetchedResultsController<PageMO>
  private let pagesPublisher: CurrentValueSubject<[MangaPage], Never>

  var pages: AnyPublisher<[MangaPage], Never> {
    pagesPublisher.eraseToAnyPublisher()
  }

  init(
    mangaId: String,
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<PageMO>(entityName: "Page")

    fetchRequest.predicate = NSPredicate(format: "isFavorite == true AND mangaId == %@", mangaId)
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PageMO.pageId, ascending: true)]

    self.pagesPublisher = CurrentValueSubject([])
    self.fetchedResultsController = NSFetchedResultsController<PageMO>(
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
    pagesPublisher.value = fetchedResultsController.fetchedObjects?.compactMap {
      MangaPage(id: $0.pageId)
    } ?? []
  }

}

extension MangaFavoritePagesProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}

