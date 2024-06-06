//
//  TachiOSmiApp.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import SwiftUI

@main
struct TachiOSmiApp: App {

  @Environment(\.scenePhase) private var phase

  let persistenceController: PersistenceController
  let backgroundManager: BackgroundManager
  let notificationsManager: NotificationManager

  init() {
    persistenceController = PersistenceController.shared

    let env = AppEnvironment(
      persistenceContainer: persistenceController.container
    )

    AppEnv.env = env

    notificationsManager = NotificationManager()
    backgroundManager = BackgroundManager(
      mangaCrud: env.mangaCrud,
      coverCrud: env.coverCrud,
      chapterCrud: env.chapterCrud,
      refreshLibraryUseCase: RefreshLibraryUseCase(
        mangaCrud: env.mangaCrud,
        chapterCrud: env.chapterCrud,
        httpClient: BackgroundHttpClient(for: .libraryRefresh),
        systemDateTime: env.systemDateTime,
        container: persistenceController.container
      ),
      notificationManager: notificationsManager,
      systemDateTime: env.systemDateTime,
      viewMoc: persistenceController.container.viewContext
    )
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .environment(\.appOptionsStore, AppEnv.env.appOptionsStore)
        .environment(\.refreshLibraryUseCase, RefreshLibraryUseCase(
          mangaCrud: AppEnv.env.mangaCrud,
          chapterCrud: AppEnv.env.chapterCrud,
          httpClient: AppEnv.env.httpClient,
          systemDateTime: AppEnv.env.systemDateTime,
          container: persistenceController.container
        ))
        .task {
          await notificationsManager.requestNotificationPermission()
        }
    }
    .backgroundTask(.appRefresh(AppTask.libraryRefresh.identifier)) {
      await backgroundManager.handleLibraryRefresh()
    }
    .onChange(of: phase) { _, newPhase in
      switch newPhase {
      case .background: 
        backgroundManager.scheduleLibraryRefresh()
      default: 
        break
      }
    }
  }

}
