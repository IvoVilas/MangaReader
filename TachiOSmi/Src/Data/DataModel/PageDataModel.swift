//
//  PageDataModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation

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

  case transitionToPrevious(from: String, to: String)
  case transitionToNext(from: String, to: String)
  case noNextChapter(currentChapter: String)
  case noPreviousChapter(currentChapter: String)

  var id: String {
    switch self {
    case .transitionToPrevious(let from, let to):
      return "transition-page-\(to)-\(from)"

    case .transitionToNext(let from, let to):
      return "transition-page-\(from)-\(to)"

    case .noNextChapter(let chapter):
      return "no-next-chapter-\(chapter)"

    case .noPreviousChapter(let chapter):
      return "no-previous-chapter-\(chapter)"
    }
  }

}
