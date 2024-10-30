//
//  AppEnvironment.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

struct AppEnv {

  static var env: AppEnvironment!

  private init() { }

}

final class AppEnvironment {

  // Rest
  let httpClient: HttpClientType

  // Crud
  let mangaCrud: MangaCrud
  let chapterCrud: ChapterCrud
  let authorCrud: AuthorCrud
  let tagCrud: TagCrud
  let coverCrud: CoverCrud
  let pageCrud: PageCrud

  // Tools
  let systemDateTime: SystemDateTimeType
  let formatter: Formatter

  // Store
  let appOptionsStore: AppOptionsStore

  // Manager
  let databaseManager: DatabaseManager
  let fileManager: LocalFileManager

  // UseCase
  let refreshLibraryUseCase: RefreshLibraryUseCase
  let markPageAsFavoriteUseCase: MarkPageAsFavoriteUseCase
  let fetchPageUseCase: FetchPageUseCase

  init(
    persistenceContainer: NSPersistentContainer
  ) {
    httpClient = HttpClient()

    mangaCrud = MangaCrud()
    chapterCrud = ChapterCrud()
    authorCrud = AuthorCrud()
    tagCrud = TagCrud()
    coverCrud = CoverCrud()
    pageCrud = PageCrud()

    systemDateTime = SystemDateTime()
    formatter = Formatter(systemDateTime: systemDateTime)

    appOptionsStore = AppOptionsStore(
      keyValueManager: UserDefaultsManager()
    )
    databaseManager = DatabaseManager(
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      tagCrud: tagCrud,
      authorCrud: authorCrud,
      coverCrud: coverCrud,
      formatter: formatter,
      persistenceContainer: persistenceContainer
    )
    fileManager = LocalFileManager()
    refreshLibraryUseCase = RefreshLibraryUseCase(
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      httpClient: httpClient,
      systemDateTime: systemDateTime,
      container: persistenceContainer
    )
    markPageAsFavoriteUseCase = MarkPageAsFavoriteUseCase(
      fileManager: fileManager,
      crud: pageCrud,
      container: persistenceContainer
    )
    fetchPageUseCase = FetchPageUseCase(
      fileManager: fileManager,
      httpClient: httpClient,
      crud: pageCrud
    )
  }

}
