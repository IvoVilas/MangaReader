//
//  Persistence.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import CoreData

struct PersistenceController {

  static let shared = PersistenceController()

  static var preview: PersistenceController = {
    let result      = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext

    return result
  }()

  let container: NSPersistentContainer

  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "TachiOSmi")

    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }

    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        debugPrint("Unresolved error \(error), \(error.userInfo)")
      }
    })

    container.viewContext.automaticallyMergesChangesFromParent = true
  }

}
