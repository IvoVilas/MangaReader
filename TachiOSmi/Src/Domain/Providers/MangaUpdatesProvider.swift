//
//  MangaUpdatesProvider.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import CoreData
import SwiftUI

final class MangaUpdatesProvider: NSObject, ObservableObject {

  @Published var updateLogs = [MangaUpdatesLogDate]()

  private let fetchedResultsController: NSFetchedResultsController<ChapterMO>
  private let coverCrud: CoverCrud
  private let chapterCrud: ChapterCrud
  private let formatter: Formatter
  private let systemDateTime: SystemDateTimeType

  private var limit: Int = 20
  private var page: Int = 0

  init(
    coverCrud: CoverCrud,
    chapterCrud: ChapterCrud,
    formatter: Formatter,
    systemDateTime: SystemDateTimeType,
    viewMoc: NSManagedObjectContext
  ) {
    let fetchRequest = NSFetchRequest<ChapterMO>(entityName: "Chapter")

    fetchRequest.predicate = NSPredicate(format: "manga.isSaved == true")
    fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChapterMO.publishAt, ascending: false)]

    self.coverCrud = coverCrud
    self.chapterCrud = chapterCrud
    self.formatter = formatter
    self.systemDateTime = systemDateTime
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

    updatePublishedValue(withPage: 0)
  }

  func updatePublishedValue(withPage page: Int) {
    self.page = page

    let context = self.fetchedResultsController.managedObjectContext

    let logs = fetchedResultsController
      .fetchedObjects?
      .prefix((page + 1) * limit)
      .map { chapter in
        context.performAndWait {
          let cover = try? self.coverCrud.getCoverData(for: chapter.manga.id, moc: context)

          return MangaUpdateLogModel(
            manga: .from(chapter.manga, cover: cover),
            chapter: .from(chapter)
          )
        }
      }

    guard let logs else { return }

    updateLogs = Dictionary(grouping: logs) {
      systemDateTime.calculator.getStartOfDay($0.chapter.publishAt)
    }.map {
      MangaUpdatesLogDate(
        date: $0.key,
        logs: $0.value,
        dateDescription: formatter.dateAsFriendlyFormat($0.key)
      )
    }
    .sorted { $0.date > $1.date }
  }

}

extension MangaUpdatesProvider: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    updatePublishedValue(withPage: page)
  }

}

extension MangaUpdatesProvider {

  struct MangaUpdateLogModel: Identifiable {

    var id: String { chapter.id }

    let manga: MangaModel
    let chapter: ChapterModel

    var lastPageReadDescription: String? {
      if let lastPageRead = chapter.lastPageRead {
        return "Page: \(lastPageRead + 1)"
      }

      return nil
    }

    var chapterTitle: String {
      let identifier: String

      if let number = chapter.number {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
          identifier = String(format: "%.0f", number)
        } else {
          identifier = String(format: "%.2f", number).trimmingCharacters(in: ["0"])
        }
      } else {
        identifier = "N/A"
      }

      return "Chapter \(identifier)"
    }

  }

  struct MangaUpdatesLogDate: Identifiable {

    var id: String { date.ISO8601Format() }

    let date: Date
    let logs: [MangaUpdateLogModel]
    let dateDescription: String

  }

}
