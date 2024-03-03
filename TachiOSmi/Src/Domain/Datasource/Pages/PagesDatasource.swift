//
//  PagesDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine

final class PagesDatasource<Source: SourceType> {

  private let chapter: ChapterModel
  private let delegate: Source.PagesDelegate

  private let pages: CurrentValueSubject<[PageModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var pagesPublisher: AnyPublisher<[PageModel], Never> {
    pages
      .map { $0.sorted { $0.rawId < $1.rawId } }
      .eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  @MainActor var hasMorePages = true
  @MainActor private var currentPage = 0
  @MainActor private var chapterInfo: ChapterDownloadInfo?

  init(
    chapter: ChapterModel,
    delegate: Source.PagesDelegate
  ) {
    self.chapter = chapter
    self.delegate = delegate

    pages = CurrentValueSubject([])
    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func refresh() async {
    await MainActor.run {
      self.currentPage = 0
      self.hasMorePages = true
      self.pages.valueOnMain = []
      self.state.valueOnMain = .loading
    }

    var erro: DatasourceError?

    do {
      let chapterInfo = try await getDownloadInfo()

      await makePagesRequest(using: chapterInfo)
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
    }
  }

  func loadNextPages() async {
    if await !hasMorePages { return }

    var erro: DatasourceError?

    do {
      let chapterInfo = try await getDownloadInfo()

      await makePagesRequest(using: chapterInfo)
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
    }
  }

  func reloadPages(
    _ pages: [(id: Int, url: String?)]
  ) async {
    await self.tryToUpdatePages(pages.map { .loading($0.id) })

    await withTaskGroup(of: Void.self) { taskGroup in
      for info in pages {
        taskGroup.addTask {
          let id = info.id
          let url = info.url

          guard let url else {
            print("PagesDatasource -> Error building page \(id) url")

            return
          }

          var erro: DatasourceError?
          let page: PageModel

          do {
            let info = try await self.getDownloadInfo()

            guard let index = info.pages.firstIndex(where: { $0 == url }) else {
              throw DatasourceError.otherError("Page not found")
            }

            let data = try await self.delegate.fetchPage(index: index, info: info)

            page = .remote(id, data)
          } catch {
            erro = .catchError(error)
            page = .notFound(id, url)
          }

          await MainActor.run { [page, erro] in
            self.error.valueOnMain = erro
            self.tryToUpdatePage(page)
          }
        }
      }
    }
  }

  private func getDownloadInfo() async throws -> ChapterDownloadInfo {
    if let local = await chapterInfo {
      return local
    }

    let remote = try await delegate.fetchDownloadInfo(using: chapter.downloadInfo)

    await MainActor.run { chapterInfo = remote }

    return remote
  }

  @MainActor
  private func tryToUpdatePages(
    _ pages: [PageModel]
  ) {
    pages.forEach { tryToUpdatePage($0) }
  }

  @MainActor
  private func tryToUpdatePage(
    _ page: PageModel
  ) {
    if let i = pages.valueOnMain.firstIndex(where: { $0.id == page.id }) {
      pages.valueOnMain[i] = page
    }
  }

  @MainActor
  private func updateOrAppend(
    _ info: [PageModel]
  ) {
    for page in info {
      updateOrAppend(page)
    }
  }

  @MainActor
  private func updateOrAppend(
    _ page: PageModel
  ) {
    if let i = pages.valueOnMain.firstIndex(where: { $0.id == page.id }) {
      let p = pages.valueOnMain[i]

      switch (p, page) {
      case (.notFound, _):
        pages.valueOnMain[i] = page

      case (.remote, .remote):
        pages.valueOnMain[i] = page

      case (.loading, .remote):
        pages.valueOnMain[i] = page

      default:
        break
      }
    } else {
      pages.valueOnMain.append(page)
    }
  }

  @MainActor
  private func preparePageRequest(
    _ info: ChapterDownloadInfo
  ) -> [Int] {
    let limit = 10
    let offset = limit * currentPage
    let count = info.pages.count

    if offset >= count {
      hasMorePages = false

      return []
    }

    let endIndex = min(count, offset + limit)
    let pages = Array(offset ..< endIndex)

    updateOrAppend(pages.map { .loading($0) })
    currentPage += 1

    return pages
  }

}

// MARK: Fetch pages
extension PagesDatasource {

  private func makePagesRequest(
    using info: ChapterDownloadInfo
  ) async {
    let pages = await preparePageRequest(info)

    Task {
      await withTaskGroup(of: Void.self) { taskGroup in
        for index in pages {
          taskGroup.addTask {
            do {
              let data = try await self.delegate.fetchPage(index: index, info: info)

              await self.updateOrAppend(.remote(index, data))
            } catch {
              print("MangaReaderViewModel -> Page \(index) failed download: \(error)")
              let url = try? self.delegate.buildPageUrl(index: index, info: info)

              await self.updateOrAppend(.notFound(index, url))
            }
          }
        }
      }
    }
  }

}

