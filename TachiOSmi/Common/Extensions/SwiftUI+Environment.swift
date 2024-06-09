//
//  SwiftUI+Environment.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 20/05/2024.
//

import Foundation
import SwiftUI
import CoreData

extension EnvironmentValues {
  
  var refreshLibraryUseCase: RefreshLibraryUseCase {
    get { self[RefreshLibraryUseCaseKey.self] }
    set { self[RefreshLibraryUseCaseKey.self] = newValue }
  }

  var persistenceContainer: NSPersistentContainer {
    get { self[PersistenceContainerKey.self] }
    set { self[PersistenceContainerKey.self] = newValue }
  }

  var appOptionsStore: AppOptionsStore {
    get { self[AppOptionsStoreKey.self] }
    set { self[AppOptionsStoreKey.self] = newValue }
  }

  var router: Router {
    get { self[RouterKey.self] }
    set { self[RouterKey.self] = newValue }
  }

}

private struct RefreshLibraryUseCaseKey: EnvironmentKey {
  
  static let defaultValue = RefreshLibraryUseCase(
    mangaCrud: MangaCrud(),
    chapterCrud: ChapterCrud(),
    httpClient: HttpClient(),
    systemDateTime: SystemDateTime(),
    container: PersistenceController.preview.container
  )

}

private struct PersistenceContainerKey: EnvironmentKey {

  static let defaultValue = PersistenceController.preview.container

}

private struct AppOptionsStoreKey: EnvironmentKey {

  static let defaultValue = AppOptionsStore.inMemory()

}

private struct RouterKey: EnvironmentKey {

  static let defaultValue = Router()

}
