//
//  SwiftUI+Environment.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 20/05/2024.
//

import Foundation
import SwiftUI

extension EnvironmentValues {
  
  var refreshLibraryUseCase: RefreshLibraryUseCase {
    get { self[RefreshLibraryUseCaseKey.self] }
    set { self[RefreshLibraryUseCaseKey.self] = newValue }
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
