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

  // Tools
  let systemDateTime: SystemDateTimeType
  let formatter: Formatter

  // Store
  let appOptionsStore: AppOptionsStore

  // Manager
  let databaseManager: DatabaseManager

  // Refresh
  let refreshLibraryUseCase: RefreshLibraryUseCase

  init(
    persistenceContainer: NSPersistentContainer
  ) {
    httpClient = HttpClient()

    mangaCrud = MangaCrud()
    chapterCrud = ChapterCrud()
    authorCrud = AuthorCrud()
    tagCrud = TagCrud()
    coverCrud = CoverCrud()

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
    refreshLibraryUseCase = RefreshLibraryUseCase(
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      httpClient: httpClient,
      systemDateTime: systemDateTime,
      container: persistenceContainer
    )
  }

}
