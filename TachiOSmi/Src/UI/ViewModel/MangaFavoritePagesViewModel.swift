//
//  MangaFavoritePagesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/10/2024.
//

import Foundation
import SwiftUI
import Combine

final class MangaFavoritePagesViewModel: ObservableObject {

  @Published var title: String
  @Published var spotlightPage: StoredPageModel?
  @Published var pages: [StoredPageModel]

  private var observers = Set<AnyCancellable>()

  init(
    mangaPages: MangaFavoritePages
  ) {
    title = mangaPages.manga.title
    spotlightPage = mangaPages.pages.first
    pages = Array(mangaPages.pages.dropFirst())
  }

}
