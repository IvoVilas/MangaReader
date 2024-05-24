//
//  Persistence.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import CoreData
import UIKit

final class PersistenceController {

  static let shared = PersistenceController()

  let container: NSPersistentContainer

  static var preview: PersistenceController = {
    let controller = PersistenceController(inMemory: true)

    initPreviewMocData(
      context: controller.container.newBackgroundContext()
    )

    return controller
  }()

  init(inMemory: Bool = false) {

    container = NSPersistentContainer(name: "TachiOSmi")

    if inMemory {
      container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

    container.loadPersistentStores { description, error in
      if let error = error {
        fatalError("Error: \(error.localizedDescription)")
      }
    }

    container.viewContext.automaticallyMergesChangesFromParent = true
  }

}

extension PersistenceController {

  private static func initPreviewMocData(
    context: NSManagedObjectContext
  ) {
    context.performAndWait {
      let manga = MangaMO(
        id: "1",
        title: "Jujutsu Kaisen",
        synopsis: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged",
        isSaved: true,
        statusId: MangaStatus.ongoing.id,
        lastUpdateAt: Date(),
        sourceId: Source.mangadex.id,
        readingDirectionId: ReadingDirection.leftToRight.id,
        moc: context
      )

      guard let manga else { return }

      for i in 0..<30 {
        guard let chapter = ChapterMO(
          id: "\(i)",
          chapter: Double(i),
          title: nil,
          numberOfPages: 20,
          publishAt: Date().addingTimeInterval(Double(i) * 1_000),
          urlInfo: "\(i)",
          manga: manga,
          moc: context
        ) else {
          continue
        }

        manga.chapters.insert(chapter)
      }

      _ = CoverMO(
        mangaId: "1",
        data: UIImage.jujutsuCover.pngData() ?? Data(),
        moc: context
      )

      _ = try? context.saveIfNeeded()
    }
  }

}
