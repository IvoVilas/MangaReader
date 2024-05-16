//
//  Persistence.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import CoreData

struct PersistenceController {

  static let shared = PersistenceController()

  let container: NSPersistentContainer

  static var preview: PersistenceController = {
    let controller = PersistenceController(inMemory: true)

    // Mock data if wanted

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
