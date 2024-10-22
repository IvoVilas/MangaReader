//
//  RefreshLibraryUseCase.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 16/05/2024.
//

import Foundation
import CoreData

final class RefreshLibraryUseCase: ObservableObject {

  enum RefreshStatus {

    case idle
    case starting
    case requesting
    case parsing
    case done
    case error

    var isError: Bool {
      return self == .error
    }

    var progress: CGFloat {
      switch self {
      case .idle:
        return 0

      case .starting:
        return 0.1

      case .requesting:
        return 0.33

      case .parsing:
        return 0.66

      case .done, .error:
        return 1
      }
    }

  }

  private let mangaCrud: MangaCrud
  private let chapterCrud: ChapterCrud
  private let httpClient: HttpClientType
  private let systemDateTime: SystemDateTimeType
  private let container: NSPersistentContainer

  @MainActor private var refreshing = false

  @Published var refreshStatus = [String: RefreshStatus]()

  init(
    mangaCrud: MangaCrud,
    chapterCrud: ChapterCrud,
    httpClient: HttpClientType,
    systemDateTime: SystemDateTimeType,
    container: NSPersistentContainer
  ) {
    self.mangaCrud = mangaCrud
    self.httpClient = httpClient
    self.chapterCrud = chapterCrud
    self.systemDateTime = systemDateTime
    self.container = container
  }

  func refresh() async -> [String: [String]] {
    if await refreshing {
      print("RefreshLibraryUseCase -> Already refresing")

      return [:]
    }

    print("RefreshLibraryUseCase -> Started library refresh...")

    await MainActor.run { refreshing = true }

    do {
      let context = container.viewContext

      let now = systemDateTime.now
      let (sources, status) = try await context.perform {
        let mangas = try self.mangaCrud.getAllMangas(saved: true, moc: context)

        let status = mangas.reduce(into: [String: RefreshStatus]()) { $0[$1.id] = .starting }
        let sources = mangas.reduce(into: [String: [String]]()) { $0[$1.sourceId, default: []].append($1.id) }

        return (sources, status)
      }

      await MainActor.run { self.refreshStatus = status }

      let updates = await withTaskGroup(of: (String, [String]).self, returning: [String: [String]].self) { taskGroup in
        let context = container.newBackgroundContext()

        for (source, ids) in sources {
          let source = Source.safeInit(from: source)
          let delegate = source.refreshDelegateType.init(httpClient: self.httpClient)

          print("RefreshLibraryUseCase -> Refresing \(ids.count) \(source.name) mangas ")

          for id in ids {
            taskGroup.addTask {
              let newChapters = await self.refreshChapters(
                mangaId: id,
                delegate: delegate,
                context: context,
                now: now
              )

              return (id, newChapters)
            }
          }
        }

        return await taskGroup.reduce(into: [:]) { (collection, result) in
          let (id, chapters) = result

          if chapters.count > 0 {
            collection[id] = chapters
          }
        }
      }

      print("RefreshLibraryUseCase -> Finished refreshing library")

      await MainActor.run {
        refreshing = false
        refreshStatus = [:]
      }

      return updates
    } catch {
      print("RefreshLibraryUseCase -> Error during library refresh: \(error)")
    }

    await MainActor.run {
      refreshing = false
      refreshStatus = [:]
    }

    return [:]
  }

}

extension RefreshLibraryUseCase {

  // Only returns newly created chapters
  private func refreshChapters(
    mangaId: String,
    delegate: RefreshDelegateType,
    context: NSManagedObjectContext,
    now: Date
  ) async -> [String] {
    do {
      await updateRefreshStatus(mangaId, to: .requesting)

      let data = try await delegate.fetchRefreshData(mangaId, updateCover: false)

      await updateRefreshStatus(mangaId, to: .parsing)

      let newChapters = try await context.perform {
        guard let manga = try self.mangaCrud.getManga(mangaId, moc: context) else {
          throw DatasourceError.databaseError("Manga \(mangaId) not found")
        }

        var newChapters = [String]()

        for chapter in data.chapters {
          do {
            let (didCreate, chapter) = try self.chapterCrud.didCreateOrUpdateChapter(
              id: chapter.id,
              chapterNumber: chapter.number,
              title: chapter.title,
              numberOfPages: chapter.numberOfPages,
              publishAt: chapter.publishAt,
              urlInfo: chapter.downloadInfo,
              manga: manga,
              moc: context
            )

            if didCreate {
              newChapters.append(chapter.id)
            }
          } catch {
            continue
          }
        }

        self.mangaCrud.updateLastUpdateAt(manga, date: now)

        _ = try context.saveIfNeeded() // TODO: Reduce saves (currently saving once per manga)

        return newChapters
      }

      await updateRefreshStatus(mangaId, to: .done)

      return newChapters
    } catch {
      await updateRefreshStatus(mangaId, to: .error)

      print("Error during \(mangaId) refresh: \(error.localizedDescription)")

      return []
    }
  }

  @MainActor
  private func updateRefreshStatus(
    _ id: String,
    to status: RefreshStatus
  ) {
    refreshStatus[id] = status
  }

}
