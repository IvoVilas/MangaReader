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

    let env = AppEnvironment(
      persistenceContainer: persistenceController.container
    )

    AppEnv.env = env
  }

  var body: some Scene {
    WindowGroup {
      ContentView(
        sourcesViewModel: MangaSourcesViewModel(),
        appOptionsStore: AppEnv.env.appOptionsStore
      )
      .environment(\.managedObjectContext, persistenceController.container.viewContext)
      .environment(\.refreshLibraryUseCase, RefreshLibraryUseCase(
        mangaCrud: AppEnv.env.mangaCrud,
        chapterCrud: AppEnv.env.chapterCrud,
        httpClient: AppEnv.env.httpClient,
        systemDateTime: AppEnv.env.systemDateTime,
        container: persistenceController.container
      ))
    }
  }

}
