//
//  MangaDetailsViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 18/02/2024.
//

import Foundation
import SwiftUI
import Combine
import CoreData

final class MangaDetailsViewModel: ObservableObject {

  @Published var manga: MangaModel
  @Published var chapters: [ChapterCell]
  @Published var chaptersCount: Int
  @Published var missingChaptersCount: Int
  @Published var isLoading: Bool
  @Published var isImageLoading: Bool
  @Published var error: DatasourceError?
  @Published var info: String?

  @Published var isSelectionOn: Bool
  @Published var selectedChapters: Set<String>
  @Published var toolbarActions: [ToolbarAction]

  private let chaptersProvider: MangaChaptersProvider
  private let chaptersDatasource: ChaptersDatasource

  private let detailsProvider: MangaDetailsProvider
  private let detailsDatasource: DetailsDatasource

  private let source: Source
  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let moc: NSManagedObjectContext

  private let sortChaptersUseCase: SortChaptersUseCase
  private let missingChaptersUseCase: MissingChaptersUseCase

  private var observers = Set<AnyCancellable>()

  init(
    manga: MangaSearchResult,
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    coverCrud: CoverCrud,
    authorCrud: AuthorCrud,
    tagCrud: TagCrud,
    httpClient: HttpClientType,
    systemDateTime: SystemDateTimeType,
    appOptionsStore: AppOptionsStore,
    container: NSPersistentContainer
  ) {
    self.source = manga.source
    self.mangaCrud = mangaCrud
    self.chapterCrud = chapterCrud
    self.moc = container.newBackgroundContext()

    let viewMoc = container.viewContext

    sortChaptersUseCase = SortChaptersUseCase()
    missingChaptersUseCase = MissingChaptersUseCase()

    chaptersProvider = MangaChaptersProvider(
      mangaId: manga.id,
      viewMoc: viewMoc
    )
    chaptersDatasource = ChaptersDatasource(
      mangaId: manga.id,
      delegate: source.chaptersDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      systemDateTime: systemDateTime,
      moc: moc
    )

    detailsProvider = MangaDetailsProvider(
      mangaId: manga.id,
      coverCrud: coverCrud,
      viewMoc: viewMoc
    )
    detailsDatasource = DetailsDatasource(
      source: source, 
      mangaId: manga.id,
      delegate: source.detailsDelegateType.init(httpClient: httpClient),
      mangaCrud: mangaCrud,
      coverCrud: coverCrud,
      authorCrud: authorCrud, 
      tagCrud: tagCrud,
      appOptionsStore: appOptionsStore,
      moc: moc
    )

    self.manga = MangaModel(
      id: manga.id,
      title: manga.title,
      description: nil,
      isSaved: false,
      source: source,
      status: .unknown,
      readingDirection: .leftToRight,
      cover: manga.cover,
      tags: [],
      authors: []
    )

    chapters = []
    isLoading = false
    isImageLoading = false
    chaptersCount = 0
    missingChaptersCount = 0

    isSelectionOn = false
    selectedChapters = Set()
    toolbarActions = []

    detailsProvider.$details
      .removeDuplicates()
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.manga = $0
      }
      .store(in: &observers)

    chaptersProvider.$chapters
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in
        self?.setChapters($0)
      }
      .store(in: &observers)

    Publishers.CombineLatest(
      detailsDatasource.statePublisher,
      chaptersDatasource.statePublisher
    )
    .map { $0.0.isLoading || $0.1.isLoading }
    .removeDuplicates()
    .receive(on: DispatchQueue.main)
    .sink { [weak self] in self?.isLoading = $0 }
    .store(in: &observers)

    Publishers.CombineLatest(
      detailsDatasource.errorPublisher,
      chaptersDatasource.errorPublisher
    )
    .receive(on: DispatchQueue.main)
    .map {
      if let error = $0 { return error }
      if let error = $1 { return error }

      return nil
    }
    .sink { [weak self] in self?.error = $0 }
    .store(in: &observers)
  }

  // TODO: Maybe remove from main thread
  private func setChapters(_ chapters: [ChapterModel]) {
    let sortedChapters = sortChaptersUseCase.sortByNumber(chapters)
    let missing = missingChaptersUseCase.calculateMissingChapters(sortedChapters)

    self.chapters = addMissingChapters(missing, to: sortedChapters)
    self.chaptersCount = chapters.count
    self.missingChaptersCount = missing.reduce(into: 0) { $0 += $1.count }
  }

  private func turnOffSelection() {
    isSelectionOn = false
    selectedChapters = []
  }

  private func markChaptersAsRead(_ isRead: Bool = true) {
    isLoading = true

    markChaptersAsRead(selectedChapters, isRead: isRead)

    turnOffSelection()

    isLoading = false
  }

  private func markChaptersBellowAsRead() {
    isLoading = true

    let id = selectedChapters.first
    let index = chapters.firstIndex {
      switch $0 {
      case .missing:
        return false

      case .chapter(let chapter):
        return chapter.id == id
      }
    }

    guard let index else { return }

    let ids = chapters.reversed()[0..<chapters.count - index].compactMap { entry -> String? in
      switch entry {
      case .missing:
        return nil

      case .chapter(let chapter):
        return chapter.id
      }
    }

    markChaptersAsRead(ids, isRead: true)

    turnOffSelection()

    isLoading = false
  }

}

// MARK: Actions
extension MangaDetailsViewModel {

  func setupData() async {
    await detailsDatasource.refresh()
    await chaptersDatasource.refresh()
  }

  func forceRefresh() async {
    await detailsDatasource.refresh(force: true)
    await chaptersDatasource.refresh(force: true)
  }

  func saveManga(_ save: Bool) async {
    do {
      let context = moc

      try await context.perform {
        guard let manga = try self.mangaCrud.getManga(self.manga.id, moc: context) else {
          throw CrudError.mangaNotFound(id: self.manga.id)
        }

        self.mangaCrud.updateIsSaved(manga, isSaved: save)

        _ = try context.saveIfNeeded()
      }

      await MainActor.run {
        info = save ? "Manga added to library" : "Manga removed from library"
      }
    } catch {
      await MainActor.run {
        self.error = DatasourceError.catchError(error)
      }
    }
  }

  func selectItem(_ chapterId: String) {
    if selectedChapters.contains(chapterId) {
      selectedChapters.remove(chapterId)
      isSelectionOn = !selectedChapters.isEmpty
    } else {
      selectedChapters.insert(chapterId)
    }
    
    toolbarActions = calculateToolbarActions(
      selected: selectedChapters
    )
  }

  func onToolbarAction(_ action: ToolbarAction) {
    switch action {
    case .close:
      turnOffSelection()

    case .markAsRead:
      markChaptersAsRead()

    case .markAsUnread:
      markChaptersAsRead(false)
      
    case .markBellowAsRead:
      markChaptersBellowAsRead()
    }
  }

}

// MARK: Helpers
extension MangaDetailsViewModel {

  private func markChaptersAsRead(_ ids: any Collection<String>, isRead: Bool) {
    let context = moc

    context.performAndWait {
      for id in ids {
        guard let chapter = try? chapterCrud.getChapter(id, moc: context) else {
          continue
        }

        chapterCrud.updateIsRead(chapter, isRead: isRead)
        chapterCrud.updateLastPageRead(chapter, lastPageRead: nil)
      }

      _ = try? context.saveIfNeeded()
    }
  }

  private func addMissingChapters(
    _ missing: [MissingChaptersModel],
    to chapters: [ChapterModel]
  ) -> [ChapterCell] {
    var mappedChapters = chapters.map { ChapterCell.chapter($0) }

    guard !missing.isEmpty else {
      return mappedChapters
    }

    for m in missing {
      let index = mappedChapters.firstIndex {
        switch $0 {
        case .missing:
          return false

        case .chapter(let chapter):
          guard let number = chapter.number else { return false }

          return Int(number) == Int(m.number) - 1
        }
      }

      if let index {
        mappedChapters.insert(.missing(m), at: index)
      }
    }

    return mappedChapters
  }

  private func calculateToolbarActions(
    selected: Set<String>
  ) -> [ToolbarAction] {
    if selected.isEmpty {
      return []
    }

    var actions: [ToolbarAction] = [.close]

    var allRead = true
    var allUnread = true

    for id in selected {
      guard allRead || allUnread else { break }

      guard let entry = chapters.first(where: { $0.id == id }) else {
        continue
      }

      switch entry {
      case .chapter(let chapter):
        if (chapter.lastPageRead ?? 0) > 0 {
          allUnread = false
          allRead = false
        } else if chapter.isRead {
          allUnread = false
        } else {
          allRead = false
        }

      case .missing:
        continue
      }
    }

    if !allRead {
      actions.append(.markAsRead)
    }

    if !allUnread {
      actions.append(.markAsUnread)
    }

    if selected.count == 1 {
      actions.append(.markBellowAsRead)
    }

    return actions
  }

}

// MARK: Enum
extension MangaDetailsViewModel {

  enum ChapterCell: Identifiable {
    case chapter(ChapterModel)
    case missing(MissingChaptersModel)

    var id: String {
      switch self {
      case .chapter(let chapter):
        return chapter.id

      case .missing(let missing):
        return missing.id
      }
    }

    var number: Double? {
      switch self {
      case .chapter(let chapter):
        return chapter.number

      case .missing(let missing):
        return Double(missing.number)
      }
    }
  }

  enum ToolbarAction: Identifiable {
    case close
    case markAsRead
    case markAsUnread
    case markBellowAsRead

    var id: String {
      switch self {
      case .close:
        "close"
      case .markAsRead:
        "mark-as-read"
      case .markAsUnread:
        "mark-as-unread"
      case .markBellowAsRead:
        "mark-bellow-as-read"
      }
    }

    var icon: IconSource {
      switch self {
      case .close:
        return .asset(.xmark)
      case .markAsRead:
        return .asset(.doneAll)
      case .markAsUnread:
        return .asset(.removeDone)
      case .markBellowAsRead:
        return .asset(.checklist)
      }
    }
  }

}

// MARK: Navigation
extension MangaDetailsViewModel {

  func getNavigator(_ chapter: ChapterModel) -> MangaReaderNavigator {
    return MangaReaderNavigator(
      source: source, 
      mangaId: manga.id,
      mangaTitle: manga.title,
      chapter: chapter,
      readingDirection: manga.readingDirection
    )
  }

}
