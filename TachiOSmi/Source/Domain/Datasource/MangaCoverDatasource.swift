//
//  MangaCoverDatasource.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import Combine
import CoreData
import UIKit

final class MangaCoverDatasource {

  private let mangaId: String

  private let httpClient: HttpClient
  private let mangaParser: MangaParser
  private let mangaCrud: MangaCrud
  private let viewMoc: NSManagedObjectContext

  private let image: CurrentValueSubject<UIImage?, Never>
  private let state: CurrentValueSubject<DatasourceState, Never>

  var imagePublisher: AnyPublisher<UIImage?, Never> {
    image.eraseToAnyPublisher()
  }

  var statePublisher: AnyPublisher<DatasourceState, Never> {
    state.eraseToAnyPublisher()
  }

  init(
    mangaId: String,
    httpClient: HttpClient,
    mangaParser: MangaParser,
    mangaCrud: MangaCrud,
    viewMoc: NSManagedObjectContext
  ) {
    self.mangaId     = mangaId
    self.httpClient  = httpClient
    self.mangaParser = mangaParser
    self.mangaCrud   = mangaCrud
    self.viewMoc     = viewMoc

    image = CurrentValueSubject(nil)
    state = CurrentValueSubject(.starting)
  }

  func setupInitialValue() async {
    guard let manga = mangaCrud.getManga(mangaId, moc: viewMoc) else {
      print("MangaCoverDatasource -> Manga not found \(mangaId)")

      return
    }

    guard
      let coverData = manga.coverArt,
      let coverImage = UIImage(data: coverData)
    else {
      await refresh()

      return
    }

    image.value = coverImage
  }

  func refresh() async {
    let result = await Task.detached { () -> Data? in
      guard let coverFileName = await self.makeMangaIndexRequest() else {
        print("MangaCoverDatasource -> coverFileName not found")

        return nil
      }

      return await self.makeCoverRequest(coverFileName: coverFileName)
    }.value

    guard let result else {
      print("MangaCoverDatasource -> No data from request")

      return
    }

    image.value = UIImage(data: result)

    await PersistenceController.shared.container.performBackgroundTask { moc in
      guard let manga = self.mangaCrud.getManga(self.mangaId, moc: moc) else {
        print("MangaCoverDatasource Error -> Manga not found \(self.mangaId)")

        return
      }

      self.mangaCrud.updateCoverArt(manga, data: result)

      if !moc.saveIfNeeded(rollbackOnError: true).isSuccess {
        print("MangaCoverDatasource Error -> Database update failed")
      }
    }
  }

  private func makeMangaIndexRequest() async -> String? {
    let json: [String: Any] = await httpClient.makeGetRequest(
      url: "https://api.mangadex.org/manga/\(mangaId)",
      parameters: ["includes[]": "cover_art"]
    )

    guard let dataJson = json["data"] as? [String: Any] else {
      print("MangaCoverDatasource -> Error creating response json")

      return nil
    }

    if let relationships = dataJson["relationships"] as? [[String: Any]] {
      for relationshipJson in relationships {
        if relationshipJson["type"] as? String == "cover_art" {
          if let attributesJson = relationshipJson["attributes"] as? [String: Any] {
            return attributesJson["fileName"] as? String
          }
        }
      }
    }

    return nil
  }

  private func makeCoverRequest(
    coverFileName: String
  ) async -> Data? {
    return await httpClient.makeGetRequest(
      url: "https://uploads.mangadex.org/covers/\(mangaId)/\(coverFileName).256.jpg"
    )
  }

}
