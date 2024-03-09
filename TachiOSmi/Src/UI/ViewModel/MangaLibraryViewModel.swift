//
//  MangaLibraryViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 09/03/2024.
//

import Foundation
import SwiftUI
import CoreData

@Observable
final class MangaLibraryViewModel {

  private let mangaCrud: MangaCrud
  private let coverCrud: CoverCrud

  private(set) var sources: [Source]
  private(set) var mangas: [MangaWrapper]

  init(
    mangaCrud: MangaCrud,
    coverCrud: CoverCrud
  ) {
    self.mangaCrud = mangaCrud
    self.coverCrud = coverCrud

    mangas = []
    sources = [
      Source.mangadex,
      Source.manganelo
    ]
  }

  func refreshLibrary() {
    var res = [MangaWrapper]()

    for source in sources {
      let moc = source.viewMoc

      moc.performAndWait {
        guard let mangas = try? mangaCrud.getAllSavedMangas(moc: moc) else {
          return
        }

        for manga in mangas {
          res.append(
            MangaWrapper(
              source: source,
              manga: .from(
                manga,
                cover: try? coverCrud.getCoverData(for: manga.id, moc: moc)
              )
            )
          )
        }
      }
    }

    mangas = res.sorted { $0.manga.title < $1.manga.title }
  }

}

extension MangaLibraryViewModel {

  struct MangaWrapper: Hashable, Identifiable {

    let source: Source
    let manga: MangaModel

    var id: String { manga.id }

  }

}
