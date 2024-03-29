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
  let httpClient: HttpClient

  // Crud
  let mangaCrud: MangaCrud
  let chapterCrud: ChapterCrud
  let authorCrud: AuthorCrud
  let tagCrud: TagCrud
  let coverCrud: CoverCrud

  // Tools
  let systemDateTime: SystemDateTimeType

  init() {
    httpClient = HttpClient()

    mangaCrud   = MangaCrud()
    chapterCrud = ChapterCrud()
    authorCrud  = AuthorCrud()
    tagCrud     = TagCrud()
    coverCrud   = CoverCrud()

    systemDateTime = SystemDateTime()
  }

}
