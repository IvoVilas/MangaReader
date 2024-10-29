//
//  MangaFavoritesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 24/10/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class MangaFavoritesViewModel: ObservableObject {
 
  private let provider: FavoritePagesProvider

  @Published var mangas: [MangaFavoritePages]

  private var observers = Set<AnyCancellable>()

  init() {
    self.provider = FavoritePagesProvider(
      mangaCrud: AppEnv.env.mangaCrud,
      coverCrud: AppEnv.env.coverCrud,
      fetchPageUseCase: AppEnv.env.fetchPageUseCase,
      viewMoc: PersistenceController.shared.container.viewContext
    )
    self.mangas = provider.currentPages

    observeProvider()
  }

  private func observeProvider() {
    provider.pages
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.mangas = $0.sorted { $0.manga.title < $1.manga.title } }
      .store(in: &observers)
  }

}
