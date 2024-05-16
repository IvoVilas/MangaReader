//
//  MangaLibraryProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import CoreData
import SwiftUI

final class MangaLibraryProvider: NSObject, ObservableObject {

  @Published var mangas = [MangaWrapper]()

  private let fetchedResultsController: NSFetchedResultsController<MangaMO>
  private let coverCrud: CoverCrud
  private let chapterCrud: ChapterCrud

  init(
    coverCrud: CoverCrud,
    chapterCrud: ChapterCrud,
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<MangaMO>(entityName: "Manga")

    fetchRequest.predicate = NSPredicate(format: "isSaved == true")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MangaMO.title, ascending: true)]

    self.coverCrud = coverCrud
    self.chapterCrud = chapterCrud
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

    mangas = (fetchedResultsController.fetchedObjects ?? [])
      .compactMap { manga in
        var res: MangaWrapper?

        context.performAndWait {
          let unreadChapters = try? self.chapterCrud.getUnreadChaptersCount(mangaId: manga.id, moc: context)
          let coverData = try? self.coverCrud.getCoverData(for: manga.id, moc: context)

          res = MangaWrapper(
            unreadChapters: unreadChapters ?? 0,
            source: .safeInit(from: manga.sourceId),
            manga: MangaSearchResult(
              id: manga.id,
              title: manga.title,
              cover: coverData
            )
          )
        }

        return res
      }
  }

}

extension MangaLibraryProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}

extension MangaLibraryProvider {

  struct MangaWrapper: Hashable, Identifiable {

    let unreadChapters: Int
    let source: Source
    let manga: MangaSearchResult

    var id: String { manga.id }

  }

}
