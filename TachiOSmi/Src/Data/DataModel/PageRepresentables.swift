//
//  PageRepresentables.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation

struct StoredPageModel: Identifiable, Hashable {

  let pageId: String
  let mangaId: String
  let chapterId: String
  let pageNumber: Int
  let source: Source
  let isFavorite: Bool
  let downloadInfo: String
  let filePath: String?
  let data: Data?

  var id: String { pageId }

  static func from(_ entity: PageMO) -> StoredPageModel {
    StoredPageModel(
      pageId: entity.pageId,
      mangaId: entity.mangaId,
      chapterId: entity.chapterId,
      pageNumber: Int(entity.pageNumber),
      source: Source.safeInit(from: entity.sourceId),
      isFavorite: entity.isFavorite,
      downloadInfo: entity.downloadInfo,
      filePath: entity.filePath,
      data: nil
    )
  }

  func injectData(_ data: Data?) -> StoredPageModel {
    StoredPageModel(
      pageId: pageId,
      mangaId: mangaId,
      chapterId: chapterId,
      pageNumber: pageNumber,
      source: source,
      isFavorite: isFavorite,
      downloadInfo: downloadInfo,
      filePath: filePath,
      data: data
    )
  }

}

enum ChapterPage: Identifiable {

  case page(PageModel)
  case transition(TransitionPageModel)

  var id: String {
    switch self {
    case .page(let page):
      return page.id

    case .transition(let page):
      return page.id
    }
  }

  var isTransition: Bool {
    switch self {
    case .page:
      return false

    case .transition:
      return true
    }
  }

}

enum PageModel: Identifiable {
  
  case remote(String, Int, Data)
  case loading(String, Int)
  case notFound(String, Int)

  var id: String {
    switch self {
    case .remote, .loading, .notFound:
      return url
    }
  }

  var url: String {
    switch self {
    case .remote(let url, _, _):
      return url

    case .loading(let url, _):
      return url

    case .notFound(let url, _):
      return url
    }
  }

  var position: Int {
    switch self {
    case .remote(_, let pos, _):
      return pos

    case .loading(_, let pos):
      return pos

    case .notFound(_, let pos):
      return pos
    }
  }

}

enum TransitionPageModel: Identifiable {

  case transitionToPrevious(from: String, to: String, missingCount: Int)
  case transitionToNext(from: String, to: String, missingCount: Int)
  case noNextChapter(currentChapter: String)
  case noPreviousChapter(currentChapter: String)

  var id: String {
    switch self {
    case .transitionToPrevious(let from, let to, _):
      return "transition-page-\(to)-\(from)"

    case .transitionToNext(let from, let to, _):
      return "transition-page-\(from)-\(to)"

    case .noNextChapter(let chapter):
      return "no-next-chapter-\(chapter)"

    case .noPreviousChapter(let chapter):
      return "no-previous-chapter-\(chapter)"
    }
  }

}
