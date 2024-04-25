//
//  TachiOSmiApp.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI

@main
struct TachiOSmiApp: App {

  let persistenceController: PersistenceController

  init() {
    persistenceController = PersistenceController.shared

    let env = AppEnvironment()

    AppEnv.env = env
  }

  var body: some Scene {
    WindowGroup {
      ContentView(
        libraryViewModel: MangaLibraryViewModel(
          mangaCrud: AppEnv.env.mangaCrud,
          coverCrud: AppEnv.env.coverCrud,
          chapterCrud: AppEnv.env.chapterCrud,
          viewMoc: PersistenceController.shared.container.viewContext
        ),
        sourcesViewModel: MangaSourcesViewModel()
      )
    }
  }

}
