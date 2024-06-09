//
//  MangaSourcesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 12/03/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaSourcesViewModel: ObservableObject {

  @Published var sources: [Source]

  private var observers = Set<AnyCancellable>()

  init(
    appOptionsStore: AppOptionsStore
  ) {
    sources = appOptionsStore.allowedSources

    appOptionsStore.allowedSourcesPublisher
      .removeDuplicates()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.sources = $0 }
      .store(in: &observers)
  }

}
