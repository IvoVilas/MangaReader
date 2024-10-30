//
//  MangaFavoritePagesViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/10/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class MangaFavoritePagesViewModel: ObservableObject {

  @Published var title: String
  @Published var spotlightPage: StoredPageModel?
  @Published var pages: [StoredPageModel]

  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let viewMoc: NSManagedObjectContext
  private var observers = Set<AnyCancellable>()

  init(
    mangaPages: MangaFavoritePages,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    viewMoc: NSManagedObjectContext
  ) {
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.viewMoc = viewMoc

    title = mangaPages.manga.title
    spotlightPage = mangaPages.pages.first
    pages = Array(mangaPages.pages.dropFirst())
  }

  func navigateToChapter(
    using page: StoredPageModel?,
    router: Router
  ) {
    guard let page else { return }

    let manga = viewMoc.performAndWait { [weak self] () -> MangaModel? in
      guard let self else { return nil }

      guard let manga = self.mangaCrud.getManga(page.mangaId, moc: viewMoc) else {
        return nil
      }

      return MangaModel.from(manga)
    }

    guard let manga else { return }

    let chapter = viewMoc.performAndWait { [weak self] () -> ChapterModel? in
      guard let self else { return nil }

      guard let chapter = self.chapterCrud.getChapter(page.chapterId, moc: viewMoc) else {
        return nil
      }

      return ChapterModel.from(chapter)
    }

    guard let chapter else { return }

    let navigator = MangaReaderNavigator(
      source: page.source,
      mangaId: page.mangaId,
      mangaTitle: manga.title,
      jumpToPage: page.pageId,
      chapter: chapter,
      readingDirection: manga.readingDirection
    )

    router.navigate(using: navigator)
  }

}
