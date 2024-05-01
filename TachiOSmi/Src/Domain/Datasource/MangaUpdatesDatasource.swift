//
//  MangaUpdatesDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 23/04/2024.
//

import Foundation
import CoreData
import Combine

final class MangaUpdatesDatasource {

  private let coverCrud: CoverCrud
  private let chapterCrud: ChapterCrud
  private let systemDateTime: SystemDateTimeType
  private let viewMoc: NSManagedObjectContext

  private let logs: CurrentValueSubject<[MangaUpdateLogModel], Never>
  private let state: CurrentValueSubject<DatasourceState, Never>
  private let error: CurrentValueSubject<DatasourceError?, Never>

  @MainActor private var lastChapterDate: Date?

  var logsPublisher: AnyPublisher<[MangaUpdateLogModel], Never> {
    logs.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  var errorPublisher: AnyPublisher<DatasourceError?, Never> {
    error.eraseToAnyPublisher()
  }

  init(
    coverCrud: CoverCrud,
    chapterCrud: ChapterCrud,
    systemDateTime: SystemDateTimeType,
    viewMoc: NSManagedObjectContext
  ) {
    self.coverCrud = coverCrud
    self.chapterCrud = chapterCrud
    self.systemDateTime = systemDateTime
    self.viewMoc = viewMoc

    logs = CurrentValueSubject([])
    state = CurrentValueSubject(.starting)
    error = CurrentValueSubject(nil)
  }

  func fetchNextUpdateLogs() async {
    await MainActor.run {
      state.valueOnMain = .loading
    }

    var erro: DatasourceError?

    do {
      let date = await self.lastChapterDate ?? self.systemDateTime.now

      let results = try await viewMoc.perform {
        let localChapters = try self.chapterCrud.getChaptersPublished(
          before: date,
          count: 15,
          moc: self.viewMoc
        )

        return localChapters.compactMap { chapter in
          let cover = try? self.coverCrud.getCoverData(
            for: chapter.manga.id,
            moc: self.viewMoc
          )

          return MangaUpdateLogModel(
            chapterId: chapter.id,
            mangaTitle: chapter.manga.title,
            chapterTitle: self.getChapterTitle(from: chapter),
            publishDate: chapter.publishAt,
            lastPageRead: chapter.lastPageRead?.intValue,
            isRead: chapter.isRead,
            mangaCover: cover
          )
        }
      }

      if results.isEmpty { return }

      await MainActor.run {
        updateOrAppend(results)
        lastChapterDate = results.last?.publishDate
      }
    } catch {
      erro = DatasourceError.catchError(error)
    }

    await MainActor.run { [erro] in
      error.valueOnMain = erro
      state.valueOnMain = .normal
    }
  }

  private func getChapterTitle(
    from chapter: ChapterMO
  ) -> String {
    let identifier: String
    if let number = chapter.chapter?.doubleValue {
      if number.truncatingRemainder(dividingBy: 1) == 0 {
        identifier = String(format: "%.0f", number)
      } else {
        identifier = String(format: "%.2f", number).trimmingCharacters(in: ["0"])
      }
    } else {
      identifier = "N/A"
    }

    return "Chapter \(identifier)"
  }

  @MainActor
  private func updateOrAppend(
    _ logs: [MangaUpdateLogModel]
  ) {
    for log in logs {
      updateOrAppend(log)
    }
  }

  @MainActor
  private func updateOrAppend(
    _ log: MangaUpdateLogModel
  ) {
    if let i = logs.valueOnMain.firstIndex(where: { $0.id == log.id }) {
      logs.valueOnMain[i] = log
    } else {
      logs.valueOnMain.append(log)
    }
  }

}
