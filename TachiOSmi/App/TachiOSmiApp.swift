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
        sourcesViewModel: MangaSourcesViewModel(),
        refreshLibraryUseCase: RefreshLibraryUseCase(
          mangaCrud: AppEnv.env.mangaCrud,
          chapterCrud: AppEnv.env.chapterCrud,
          httpClient: AppEnv.env.httpClient,
          systemDateTime: AppEnv.env.systemDateTime,
          moc: persistenceController.container.newBackgroundContext()
        )
      )
      .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
  }

}
