//
//  MockRefreshDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 07/06/2024.
//

import Foundation
import UIKit

final class MockRefreshDelegate: RefreshDelegateType {

  init(httpClient: HttpClientType) { }

  func fetchRefreshData(
    _ mangaId: String,
    updateCover: Bool
  ) async throws -> MangaRefreshData {
    return MangaRefreshData(
      id: "1",
      title: "Jujutsu Kaisen",
      description: "Yuuji is a genius at track and field. But he has zero interest running around in circles, he's happy as a clam in the Occult Research Club. Although he's only in the club for kicks, things get serious when a real spirit shows up at school! Life's about to get really strange in Sugisawa Town #3 High School!",
      cover: updateCover ? UIImage.jujutsuCover.pngData() : nil,
      status: .ongoing,
      tags: [
        TagModel(id: "1", title: "Action"),
        TagModel(id: "2", title: "Shounen"),
        TagModel(id: "3", title: "Supernatural")
      ],
      authors: [AuthorModel(id: "1", name: "Akutami Gege")],
      chapters: [
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
    )
  }

}
