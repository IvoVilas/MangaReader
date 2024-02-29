//
//  PagesDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine

final class PagesDatasource<Delegate: PagesDelegateType> {

  private let chapterId: String
  private let delegate: Delegate

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
  @MainActor private var chapterInfo: Delegate.Info?

  init(
    chapterId: String,
    delegate: Delegate
  ) {
    self.chapterId = chapterId
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
    var pages = [PageModel]()
    var hasMorePages = true

    do {
      let chapterInfo = try await getDownloadInfo()

      pages = await makePagesRequest(using: chapterInfo)

      if pages.isEmpty {
        hasMorePages = false

        throw DatasourceError.otherError("No pages found")
      }
    } catch {
      erro = delegate.catchError(error)
    }

    await MainActor.run { [pages, erro, hasMorePages] in
      self.error.valueOnMain = erro
      self.pages.valueOnMain = pages
      self.hasMorePages = hasMorePages
    }
  }

  func loadNextPages() async {
    var hasMorePages = await hasMorePages

    if !hasMorePages { return }

    var erro: DatasourceError?
    var pages = [PageModel]()

    do {
      let chapterInfo = try await getDownloadInfo()

      pages = await makePagesRequest(using: chapterInfo)

      if pages.isEmpty {
        hasMorePages = false
      } else {
        await self.updateOrAppend(pages)
      }
    } catch {
      erro = delegate.catchError(error)
    }

    await MainActor.run { [erro, hasMorePages] in
      self.error.valueOnMain = erro
      self.hasMorePages = hasMorePages
    }
  }

  func reloadPages(
    _ pages: [(id: Int, url: String)]
  ) async {
    await self.tryToUpdatePages(pages.map { .loading($0.id) })

    await withTaskGroup(of: Void.self) { taskGroup in
      for info in pages {
        taskGroup.addTask {
          let id = info.id
          let url = info.url

          var erro: DatasourceError?
          let page: PageModel

          do {
            let data = try await self.delegate.fetchPage(url)

            page = .remote(id, data)
          } catch {
            erro = self.delegate.catchError(error)
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

  private func getDownloadInfo() async throws -> Delegate.Info {
    if let local = await chapterInfo {
      return local
    }

    let remote = try await delegate.fetchDownloadInfo(chapterId: chapterId)

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
  }

}

// MARK: Fetch pages
extension PagesDatasource {

  private func makePagesRequest(
    using info: Delegate.Info
  ) async -> [PageModel] {
    print("MangaReaderViewModel -> Starting chapter download")
    let page = await MainActor.run(resultType: Int.self) {
      let page = self.currentPage

      self.currentPage += 1

      return page
    }

    let limit = 10
    let offset = limit * page
    let count = info.numberOfPages

    if offset >= count {
      return []
    }

    let endIndex = min(count, offset + limit)
    let pages = offset ..< endIndex

    await updateOrAppend(pages.map { .loading($0) })

    let results = await withTaskGroup(of: PageModel.self, returning: [PageModel].self) { taskGroup in
      for index in pages {
        taskGroup.addTask {
          do {
            let data = try await self.delegate.fetchPage(index: index, info: info)

            return .remote(offset + index, data)
          } catch {
            print("MangaReaderViewModel -> Page \(offset + index) failed download: \(error)")
            guard let url = try? self.delegate.buildUrl(index: index, info: info) else {
              print ("PagesDatasource -> Error building url")

              return .notFound(offset + index, "")
            }

            return .notFound(offset + index, url)
          }
        }
      }

      return await taskGroup.reduce(into: [PageModel]()) { partialResult, page in
        partialResult.append(page)
      }
    }

    print("MangaReaderViewModel -> Ending chapter download")

    return results
  }

}

