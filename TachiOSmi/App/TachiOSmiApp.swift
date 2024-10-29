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
  let notificationManager: NotificationManager

  init() {
    persistenceController = PersistenceController.shared

    let env = AppEnvironment(
      persistenceContainer: persistenceController.container
    )

    AppEnv.env = env

    notificationManager = NotificationManager()
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
      notificationManager: notificationManager,
      systemDateTime: env.systemDateTime,
      viewMoc: persistenceController.container.viewContext
    )

    /*
    _ = env.fileManager.deleteAllImages()
    let context = persistenceController.container.viewContext
    context.performAndWait {
      guard let pages = try? env.pageCrud.getAllPages(moc: context) else {
        return
      }

      for page in pages {
        context.delete(page)
      }

      try? context.save()
    }
     */
  }

  var body: some Scene {
    WindowGroup {
      ContentView(notificationManager: notificationManager)
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
        .environment(\.appOptionsStore, AppEnv.env.appOptionsStore)
        .environment(\.refreshLibraryUseCase, AppEnv.env.refreshLibraryUseCase)
        .task {
          await notificationManager.requestNotificationPermission()
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
