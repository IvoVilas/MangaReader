//
//  MangaLibraryViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 31/05/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaLibraryViewModel: ObservableObject {

  @Published var mangas: [MangaLibraryProvider.MangaWrapper]
  @Published var layout: CollectionLayout
  @Published var gridSize: CGFloat

  private let provider: MangaLibraryProvider
  private let store: AppOptionsStore

  private var observers = Set<AnyCancellable>()

  init(
    provider: MangaLibraryProvider,
    optionsStore: AppOptionsStore
  ) {
    self.provider = provider
    self.store = optionsStore

    mangas = []
    layout = optionsStore.libraryLayout
    gridSize = CGFloat(optionsStore.libraryGridSize)

    provider.$mangas
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.mangas = $0 }
      .store(in: &observers)

    $gridSize
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.changeGridSize(to: Int($0)) }
      .store(in: &observers)
  }

  func changeLayout(to layout: CollectionLayout) {
    self.layout = layout

    store.changeProperty(.libraryLayout(layout))
  }

  private func changeGridSize(to size: Int) {
    gridSize = CGFloat(size)

    store.changeProperty(.libraryGridSize(size))
  }

}
