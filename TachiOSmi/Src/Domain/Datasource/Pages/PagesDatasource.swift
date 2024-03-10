//
//  PagesDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine

final class PagesDatasource {

  let chapter: ChapterModel
  private let delegate: PagesDelegateType

  private let pages: CurrentValueSubject<[PageModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  var pagesPublisher: AnyPublisher<[PageModel], Never> {
    pages
      .map { $0.sorted { $0.position < $1.position } }
      .eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  @MainActor private var chapterInfo: ChapterDownloadInfo?
  @MainActor private var hasMorePages = true
  @MainActor private var currentPage = 0
  @MainActor private var pagination = [Int: [String]]()
  @MainActor private var lastPageLoaded: String?

  init(
    chapter: ChapterModel,
    delegate: PagesDelegateType
  ) {
    self.chapter = chapter
    self.delegate = delegate

    pages = CurrentValueSubject([])
    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func loadChapter() async {
    print("PagesDatasource -> Started chapter loading")

    await MainActor.run { self.chapterInfo = nil }

    var erro: DatasourceError?

    do {
      let chapterInfo = try await getDownloadInfo()

      await setupPagination(using: chapterInfo)
      await makePagesRequest(using: chapterInfo)
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
    }

    print("PagesDatasource -> Endend chapter loading")
  }

  func loadNextPagesIfNeeded(
    _ id: String
  ) async {
    guard
      await hasMorePages,
      await id == lastPageLoaded
    else {
      return
    }

    print("PagesDatasource -> Started loading next page")

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

    print("PagesDatasource -> Ended loading next page")
  }

  func loadPages(
    until id: String
  ) async {
    if await !hasMorePages { return }

    print("PagesDatasource -> Started loading pages until \(id)")

    var erro: DatasourceError?

    do {
      let chapterInfo = try await getDownloadInfo()

      try await makePagesRequest(
        until: id,
        using: chapterInfo
      )
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
    }

    print("PagesDatasource -> Ended loading pages")
  }

  func reloadPages(
    _ pages: [(url: String, pos: Int)]
  ) async {
    await self.updateOrAppend(pages.map { .loading($0.url, $0.pos) })

    await withTaskGroup(of: Void.self) { taskGroup in
      for info in pages {
        taskGroup.addTask {
          let url = info.url
          let pos = info.pos

          var erro: DatasourceError?
          let page: PageModel

          do {
            let info = try await self.getDownloadInfo()

            let index = await self.pages.valueOnMain
              .first { $0.url == url }?
              .position

            guard let index else {
              throw DatasourceError.otherError("Page not found")
            }

            print("PagesDatasource -> Reloading page \(index)")

            let data = try await self.delegate.fetchPage(index: index, info: info)

            page = .remote(url, pos, data)
          } catch {
            erro = .catchError(error)
            page = .notFound(url, pos)
          }

          await MainActor.run { [page, erro] in
            self.error.valueOnMain = erro
            self.updateOrAppend(page)
          }
        }
      }
    }
  }

}

extension PagesDatasource {

  @MainActor
  private func setupPagination(
    using info: ChapterDownloadInfo
  ) {
    currentPage = 0
    hasMorePages = true
    pagination = [:]
    pages.valueOnMain = []
    state.valueOnMain = .loading

    let count = info.pages.count

    if count <= 0 {
      hasMorePages = false

      return
    }

    let limit = 10
    let pages = Array(0..<count)
    let paginationCount = Int(ceil(Double(count) / 10))

    for index in 0..<paginationCount {
      let offset = index * limit
      let end = min((index + 1) * limit, count)

      pagination[index] = Array(offset..<end).compactMap {
        (try? delegate.buildPageUrl(index: $0, info: info)) ?? UUID().uuidString
      }
    }

    self.pages.valueOnMain = pages.map {
      let url = try? self.delegate.buildPageUrl(index: $0, info: info)

      return .loading(url ?? UUID().uuidString, $0)
    }
  }

  @MainActor
  private func preparePageRequest(
    _ info: ChapterDownloadInfo
  ) -> [String] {
    guard let pages = pagination[currentPage] else {
      hasMorePages = false

      return []
    }

    currentPage += 1

    if let lastPage = pages.last {
      lastPageLoaded = lastPage
    }

    return pages
  }

  @MainActor
  private func getPagesNeedingLoading(
    pageId: String,
    info: ChapterDownloadInfo
  ) throws -> [String] {
    let page = pagination
      .filter { $0.value.contains(pageId) }
      .map { $0.key }
      .last

    guard let page else { throw DatasourceError.otherError("Page \(pageId) not found") }

    if page < currentPage {
      return []
    }

    let currentPage = currentPage

    self.currentPage = page + 1

    let pages = Array(currentPage...page)
      .compactMap { pagination[$0] }
      .reduce(into: []) { $0.append(contentsOf: $1) }

    if let lastPage = pages.last {
      lastPageLoaded = lastPage
    }

    return pages
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

      case (.loading, .remote), (.loading, .notFound):
        pages.valueOnMain[i] = page

      default:
        break
      }
    } else {
      pages.valueOnMain.append(page)
    }
  }

}

// MARK: Fetch pages
extension PagesDatasource {

  private func getDownloadInfo() async throws -> ChapterDownloadInfo {
    if let local = await chapterInfo {
      return local
    }

    let remote = try await delegate.fetchDownloadInfo(using: chapter.downloadInfo)

    await MainActor.run { chapterInfo = remote }

    return remote
  }

  private func makePagesRequest(
    using info: ChapterDownloadInfo
  ) async {
    let pages = await preparePageRequest(info)

    Task {
      await withTaskGroup(of: Void.self) { taskGroup in
        for (index, url) in pages.enumerated() {
          taskGroup.addTask {
            do {
              let data = try await self.delegate.fetchPage(url: url, info: info)

              await self.updateOrAppend(.remote(url, index, data))
            } catch {
              print("PagesDatasource -> Page \(index) failed download: \(error)")

              await self.updateOrAppend(.notFound(url, index))
            }
          }
        }
      }
    }
  }

  private func makePagesRequest(
    until id: String,
    using info: ChapterDownloadInfo
  ) async throws {
    let pages = try await getPagesNeedingLoading(
      pageId: id,
      info: info
    )

    print("PagesDatasource -> Loading \(pages.count) pages")

    Task {
      await withTaskGroup(of: Void.self) { taskGroup in
        for (index, url) in pages.enumerated() {
          taskGroup.addTask {
            do {
              let data = try await self.delegate.fetchPage(index: index, info: info)

              await self.updateOrAppend(.remote(url, index, data))
            } catch {
              print("PagesDatasource -> Page \(index) failed download: \(error)")

              await self.updateOrAppend(.notFound(url, index))
            }
          }
        }
      }
    }
  }

}

