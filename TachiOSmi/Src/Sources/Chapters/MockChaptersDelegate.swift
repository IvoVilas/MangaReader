//
//  MockChaptersDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import Foundation

final class MockChaptersDelegate: ChaptersDelegateType {

  init(httpClient: HttpClientType) { }

  func fetchChapters(mangaId: String) async throws -> [ChapterIndexResult] {
    try await Task.sleep(nanoseconds: 500_000_000)

    return [
      ChapterIndexResult(
        id: "1",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "2",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "3",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "4",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "5",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "6",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "7",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "8",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "9",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      ),
      ChapterIndexResult(
        id: "10",
        title: nil,
        number: 1,
        numberOfPages: 20,
        publishAt: Date(),
        downloadInfo: "1"
      )
    ]
  }

}
