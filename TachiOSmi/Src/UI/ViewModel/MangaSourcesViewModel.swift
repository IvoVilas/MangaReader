//
//  MangaSourcesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import Foundation
import SwiftUI

final class MangaSourcesViewModel: ObservableObject {

  @Published var sources: [Source]

  init() {
    sources = Source.allSources()
  }

}
