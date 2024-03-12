//
//  MangaSourcesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import Foundation
import SwiftUI

@Observable
final class MangaSourcesViewModel {

  private let inMemory: Bool

  private(set) var sources: [Source]

  init(
    inMemory: Bool = false
  ) {
    self.inMemory = inMemory

    sources = Source.allSources()
  }

}

extension MangaSourcesViewModel {

  func buildSearchViewModel(
    for source: Source
  ) -> MangaSearchViewModel {
    return MangaSearchViewModel(
      source: source,
      mangaCrud: AppEnv.env.mangaCrud,
      coverCrud: AppEnv.env.coverCrud,
      httpClient: AppEnv.env.httpClient,
      viewMoc: PersistenceController.getViewMoc(for: source, inMemory: inMemory)
    )
  }

}
