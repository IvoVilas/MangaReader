//
//  Persistence.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import CoreData

protocol MangaDatabaseType {

  var container: NSPersistentContainer { get }
  var viewMoc: NSManagedObjectContext { get }

}

struct PersistenceController {

  let mangaDex: MangadexDatabase
  let mangaNelo: ManganeloDatabase

  static let shared = PersistenceController(
    mangaDex: MangadexDatabase(),
    mangaNelo: ManganeloDatabase()
  )

  static var preview: PersistenceController = {
    let mangaDex  = MangadexDatabase(inMemory: true)
    let mangaNelo = ManganeloDatabase(inMemory: true)

    return PersistenceController(
      mangaDex: mangaDex,
      mangaNelo: mangaNelo
    )
  }()

}

struct MangadexDatabase: MangaDatabaseType {

  let container: NSPersistentContainer

  var viewMoc: NSManagedObjectContext { container.viewContext }

  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "Mangadex")

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

struct ManganeloDatabase: MangaDatabaseType {

  let container: NSPersistentContainer

  var viewMoc: NSManagedObjectContext { container.viewContext }

  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "Manganelo")

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
