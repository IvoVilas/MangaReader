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

  private(set) var sources: [Source]

  init() {
    sources = Source.allSources()
  }

}
