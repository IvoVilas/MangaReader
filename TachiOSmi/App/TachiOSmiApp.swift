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

    let env = AppEnvironment(moc: persistenceController.container.viewContext)

    AppEnv.env = env
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }

}
