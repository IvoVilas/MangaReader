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
  let restRequester: RestRequester

  // Crud
  let mangaCrud: MangaCrud
  let chapterCrud: ChapterCrud
  let authorCrud: AuthorCrud
  let tagCrud: TagCrud

  // Parser
  let mangaParser: MangaParser
  let chapterParser: ChapterParser

  // Datasource
  let mangaSearchDatasource: MangaSearchDatasource

  // Tools
  let systemDateTime: SystemDateTimeType

  private let moc: NSManagedObjectContext

  init(
    moc: NSManagedObjectContext
  ) {
    self.moc = moc

    restRequester = RestRequester()

    mangaCrud   = MangaCrud()
    chapterCrud = ChapterCrud()
    authorCrud  = AuthorCrud()
    tagCrud     = TagCrud()

    mangaParser   = MangaParser()
    chapterParser = ChapterParser(
      mangaCrud: mangaCrud,
      chapterCrud: chapterCrud,
      moc: moc
    )

    mangaSearchDatasource = MangaSearchDatasource(
      restRequester: restRequester,
      mangaParser: mangaParser,
      mangaCrud: mangaCrud
    )

    systemDateTime = SystemDateTime()
  }

}
