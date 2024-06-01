//
//  MockSearchDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import Foundation
import UIKit

final class MockSearchDelegate: SearchDelegateType {

  init(httpClient: HttpClientType) { }

  func fetchTrending(page: Int) async throws -> [MangaSearchResultParsedData] {
    try await Task.sleep(nanoseconds: 3_000_000_000)

    return [
      MangaSearchResultParsedData(
        id: "1",
        title: "Jujutsu Kaisen",
        coverDownloadInfo: "1"
      ),
      MangaSearchResultParsedData(
        id: "2",
        title: "Solo Leveling",
        coverDownloadInfo: "2"
      ),
      MangaSearchResultParsedData(
        id: "3",
        title: "Sousou no Frieren",
        coverDownloadInfo: "3"
      ),
      MangaSearchResultParsedData(
        id: "4",
        title: "Berserk",
        coverDownloadInfo: "4"
      ),
      MangaSearchResultParsedData(
        id: "5",
        title: "Boruto",
        coverDownloadInfo: "5"
      ),
      MangaSearchResultParsedData(
        id: "6",
        title: "One punch man",
        coverDownloadInfo: "6"
      )
    ]
  }
  
  func fetchSearchResults(_ searchValue: String, page: Int) async throws -> [MangaSearchResultParsedData] {
    try await Task.sleep(nanoseconds: 1_500_000_000)

    return [
      MangaSearchResultParsedData(
        id: "1",
        title: "Jujutsu Kaisen",
        coverDownloadInfo: "1"
      ),
      MangaSearchResultParsedData(
        id: "2",
        title: "Solo Leveling",
        coverDownloadInfo: "2"
      ),
      MangaSearchResultParsedData(
        id: "3",
        title: "Sousou no Frieren",
        coverDownloadInfo: "3"
      ),
      MangaSearchResultParsedData(
        id: "4",
        title: "Berserk",
        coverDownloadInfo: "4"
      ),
      MangaSearchResultParsedData(
        id: "5",
        title: "Boruto",
        coverDownloadInfo: "5"
      ),
      MangaSearchResultParsedData(
        id: "6",
        title: "One punch man",
        coverDownloadInfo: "6"
      )
    ]
  }
  
  func fetchCover(mangaId: String, coverInfo: String) async throws -> Data {
    return UIImage.jujutsuCover.jpegData(compressionQuality: 1) ?? Data()
  }

}
