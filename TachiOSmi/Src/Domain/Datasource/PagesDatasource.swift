//
//  PagesDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 29/02/2024.
//

import Foundation
import Combine

final class PagesDatasource {

  struct PaginationBlock {
    var loaded: Bool
    let pages: [String]
  }

  private static let limit = 10

  private let mangaId: String
  private let chapter: ChapterModel
  private let delegate: PagesDelegateType
  private let appOptionsStore: AppOptionsStore

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
  @MainActor private var pagination = [Int: PaginationBlock]()

  init(
    mangaId: String,
    chapter: ChapterModel,
    delegate: PagesDelegateType,
    appOptionsStore: AppOptionsStore
  ) {
    self.mangaId = mangaId
    self.chapter = chapter
    self.delegate = delegate
    self.appOptionsStore = appOptionsStore

    pages = CurrentValueSubject([])
    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

}

// MARK: Datasource actions
extension PagesDatasource {

  func prepareDatasource() async {
    var erro: DatasourceError?

    do {
      let chapterInfo = try await getDownloadInfo()

      await setupPagination(using: chapterInfo)
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
      self.state.valueOnMain = .normal
    }
  }

  func loadStart() async {
    print("PagesDatasource -> Loading first page block")

    await MainActor.run { self.chapterInfo = nil }

    var erro: DatasourceError?

    do {
      let chapterInfo = try await getDownloadInfo()

      await makePagesBlockRequest(0, using: chapterInfo)
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
    }

    print("PagesDatasource -> Endend loading page block")
  }

  func loadEnd() async {
    print("PagesDatasource -> Loading last page block")

    await MainActor.run { self.chapterInfo = nil }

    var erro: DatasourceError?

    do {
      let chapterInfo = try await getDownloadInfo()
      let lastBlock = await pagination.count - 1

      await makePagesBlockRequest(lastBlock, using: chapterInfo)
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
    }

    print("PagesDatasource -> Endend loading page block")
  }

  func loadPagesIfNeeded(
    _ id: String
  ) async {
    var erro: DatasourceError?

    do {
      let blocks = await getBlocksNeedingLoading(for: id)

      if blocks.isEmpty { return }

      print("PagesDatasource -> Started loading \(blocks.count) page block")

      let chapterInfo = try await getDownloadInfo()

      for block in blocks {
        await makePagesBlockRequest(block, using: chapterInfo)
      }
    } catch {
      erro = .catchError(error)
    }

    await MainActor.run { [erro] in
      self.error.valueOnMain = erro
    }

    print("PagesDatasource -> Ended loading page block")
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

// MARK: Methods
extension PagesDatasource {

  private func getDownloadInfo() async throws -> ChapterDownloadInfo {
    if let local = await chapterInfo {
      return local
    }

    let remote = try await delegate.fetchDownloadInfo(
      mangaId: mangaId,
      using: chapter.downloadInfo,
      saveData: appOptionsStore.isDataSavingOn
    )

    await MainActor.run { chapterInfo = remote }

    return remote
  }

  private func makePagesBlockRequest(
    _ index: Int,
    using info: ChapterDownloadInfo
  ) async {
    guard let block = await pagination[index] else { return }

    await MainActor.run {
      pagination[index]?.loaded = true
    }

    Task { [block] in
      await withTaskGroup(of: Void.self) { taskGroup in
        for (offset, url) in block.pages.enumerated() {
          taskGroup.addTask {
            do {
              let index = index * PagesDatasource.limit + offset
              let data = try await self.delegate.fetchPage(url: url)

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

// MARK: Helpers
extension PagesDatasource {

  @MainActor
  private func getBlocksNeedingLoading(
    for pageId: String
  ) -> [Int] {
    var res = [Int]()

    guard let block = pagination
      .filter ({ $0.value.pages.contains(pageId) })
      .first
    else {
      return res
    }

    let index = block.key

    if block.value.loaded == false {
      res.append(index)
    }

    if
      pageId == block.value.pages.last,
      pagination[index + 1] != nil,
      pagination[index + 1]?.loaded == false
    {
      res.append(index + 1)
    }

    return res
  }

  @MainActor
  private func setupPagination(
    using info: ChapterDownloadInfo
  ) {
    pagination = [:]
    pages.valueOnMain = []

    let count = info.pages.count

    if count <= 0 { return }

    let pages = Array(0..<count)
    let paginationCount = Int(ceil(Double(count) / Double(PagesDatasource.limit)))

    for index in 0..<paginationCount {
      let offset = index * PagesDatasource.limit
      let end = min((index + 1) * PagesDatasource.limit, count)

      pagination[index] = PaginationBlock(
        loaded: false,
        pages: Array(offset..<end).compactMap {
          (try? delegate.buildPageUrl(index: $0, info: info)) ?? UUID().uuidString
        }
      )
    }

    self.pages.valueOnMain = pages.map {
      let url = try? self.delegate.buildPageUrl(index: $0, info: info)

      return .loading(url ?? UUID().uuidString, $0)
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
