//
//  ChaptersChangesProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 31/05/2024.
//

import Foundation
import CoreData
import Combine

final class ChaptersInfoProvider: NSObject {

  private let fetchedResultsController: NSFetchedResultsController<ChapterMO>
  private let infoPublisher: CurrentValueSubject<[ChaptersInfo], Never>

  var info: AnyPublisher<[ChaptersInfo], Never> {
    infoPublisher.eraseToAnyPublisher()
  }

  init(
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<ChapterMO>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.isSaved == true")
    fetchRequest.sortDescriptors = [
      NSSortDescriptor(keyPath: \ChapterMO.manga.id, ascending: true),
      NSSortDescriptor(keyPath: \ChapterMO.chapter, ascending: true)
    ]

    self.infoPublisher = CurrentValueSubject([])
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
    let results = (fetchedResultsController.fetchedObjects ?? [])

    context.performAndWait {
      infoPublisher.value = Dictionary(grouping: results) { $0.manga.id }
        .map { (id, chapters) -> ChaptersInfo in
          ChaptersInfo(
            mangaId: id,
            chapterCount: chapters.count,
            unreadChapters: chapters.filter { !$0.isRead }.count,
            latestChapter: chapters.compactMap { $0.publishAt }.sorted { $0 < $1 }.last
          )
        }
        .reduce(into: [ChaptersInfo]()) { $0.append($1) }
    }
  }

}

extension ChaptersInfoProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue()
  }

}

extension ChaptersInfoProvider {

  struct ChaptersInfo {
    let mangaId: String
    let chapterCount: Int
    let unreadChapters: Int
    let latestChapter: Date?
  }

}