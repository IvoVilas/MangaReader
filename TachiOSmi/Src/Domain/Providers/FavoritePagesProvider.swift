//
//  FavoritePagesProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 24/10/2024.
//

import Foundation
import Combine
import CoreData

final class FavoritePagesProvider: NSObject {

  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud
  private let fetchPageUseCase: FetchPageUseCase

  private let fetchedResultsController: NSFetchedResultsController<PageMO>
  private let pagesPublisher: CurrentValueSubject<[MangaFavoritePages], Never>

  var pages: AnyPublisher<[MangaFavoritePages], Never> {
    pagesPublisher.eraseToAnyPublisher()
  }

  var currentPages: [MangaFavoritePages] {
    pagesPublisher.value
  }

  init(
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud,
    fetchPageUseCase: FetchPageUseCase,
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<PageMO>(entityName: "Page")

    fetchRequest.predicate = NSPredicate(format: "isFavorite == true")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PageMO.mangaId, ascending: true)]

    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud
    self.fetchPageUseCase = fetchPageUseCase
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
    let context = fetchedResultsController.managedObjectContext

    pagesPublisher.value = buildData(
      fetchedResultsController.fetchedObjects,
      moc: context
    )
  }

  private func buildData(
    _ objects: [PageMO]?,
    moc: NSManagedObjectContext
  ) -> [MangaFavoritePages] {
    guard let objects else { return [] }

    return objects.reduce(into: [String: [StoredPageModel]]()) { partialResult, entity in
      let page = StoredPageModel.from(entity)
      let mangaId = page.mangaId

      partialResult[mangaId, default: []].append(page)
    }
    .compactMap {
      return buildFavoritePages(mangaId: $0, storedPages: $1, moc: moc)
    }
  }

  private func buildFavoritePages(
    mangaId: String,
    storedPages: [StoredPageModel],
    moc: NSManagedObjectContext
  ) -> MangaFavoritePages? {
    moc.performAndWait {
      guard let manga = try? mangaCrud.getManga(mangaId, moc: moc) else {
        return nil
      }

      let cover = try? coverCrud.getCoverData(
        for: manga.id,
        moc: moc
      )

      let pages = storedPages.compactMap { storedPage -> StoredPageModel? in
        return fetchPageUseCase.fetchPageModel(storedPage: storedPage)
      }

      return MangaFavoritePages(
        manga: MangaModel.from(manga, cover: cover),
        pages: pages
      )
    }
  }

}

extension FavoritePagesProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}
