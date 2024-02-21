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

  private let mangaParser: MangaParser
  private let mangaCrud: MangaCrud
  private let moc: NSManagedObjectContext

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
    mangaParser: MangaParser,
    mangaCrud: MangaCrud,
    moc: NSManagedObjectContext
  ) {
    self.mangaId     = mangaId
    self.mangaParser = mangaParser
    self.mangaCrud   = mangaCrud
    self.moc         = moc

    image = CurrentValueSubject(nil)
    state = CurrentValueSubject(.starting)
  }

  func refresh() async {
    guard let coverFileName = await makeMangaIndexRequest() else {
      print("MangaCoverDatasource -> coverFileName not found")

      return
    }

    let result = await makeCoverRequest(coverFileName: coverFileName)

    image.value = result
  }

  func setupInitialValue() {
    guard let manga = mangaCrud.getManga(mangaId, moc: moc) else {
      print("MangaCoverDatasource -> Manga not found \(mangaId)")

      return
    }

    if
      let coverData = manga.coverArt,
      let coverImage = UIImage(data: coverData)
    {
      image.value = coverImage
    } else {
      Task {
        await refresh()
      }
    }
  }

  private func makeMangaIndexRequest() async -> String? {
    let urlString = "https://api.mangadex.org/manga/\(mangaId)"

    let parameters = [
      "includes[]": "cover_art"
    ]

    var urlParameters = URLComponents(string: urlString)
    urlParameters?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

    guard let url = urlParameters?.url else {
      print ("MangaCoverDatasource -> Error creating url")

      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let response = response as? HTTPURLResponse else {
        print("MangaCoverDatasource -> Response parse error")

        return nil
      }

      guard response.statusCode == 200 else {
        print("MangaCoverDatasource -> Received response with code \(response.statusCode)")

        return nil
      }

      guard
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let dataJson = json["data"] as? [String: Any]
      else {
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
    } catch {
      print("MangaCoverDatasource -> Error during request \(error)")
    }

    return nil
  }

  private func makeCoverRequest(
    coverFileName: String
  ) async -> UIImage? {
    let urlString = "https://uploads.mangadex.org/covers/\(mangaId)/\(coverFileName).256.jpg"

    guard let url = URL(string: urlString) else {
      print ("MangaCoverDatasource -> Error creating url")

      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let response = response as? HTTPURLResponse else {
        print("MangaCoverDatasource -> Response parse error")

        return nil
      }

      guard response.statusCode == 200 else {
        print("MangaCoverDatasource -> Received response with code \(response.statusCode)")

        return nil
      }

      guard let manga = mangaCrud.getManga(mangaId, moc: moc) else {
        print("MangaParser Error -> Manga with id:\(mangaId) not found")

        return nil
      }

      mangaCrud.updateCoverArt(manga, data: data)

      _ = moc.saveIfNeeded(rollbackOnError: true)

      return UIImage(data: data)
    } catch {
      print("MangaCoverDatasource -> Error during request \(error)")
    }

    return nil
  }

}
