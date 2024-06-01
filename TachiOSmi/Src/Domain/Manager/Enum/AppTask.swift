//
//  AppTask.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 01/06/2024.
//

import Foundation

enum AppTask {

  case libraryRefresh

  var identifier: String {
    let prefix = "Moguizan.TachiOSmi.background_task"

    switch self {
    case .libraryRefresh:
      return prefix + ".library_refresh"
    }
  }

  var sessionIdentifier: String {
    let prefix = "Moguizan.TachiOSmi.background_session"

    switch self {
    case .libraryRefresh:
      return prefix + ".library_refresh"
    }
  }

}
