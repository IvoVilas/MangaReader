//
//  MockDetailsDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 28/05/2024.
//

import Foundation
import UIKit

final class MockDetailsDelegate: DetailsDelegateType {

  init(httpClient: HttpClientType) { }

  func fetchDetails(_ mangaId: String) async throws -> MangaDetailsParsedData {
    return MangaDetailsParsedData(
      id: "1",
      title: "Jujutsu Kaisen",
      description: "Yuuji is a genius at track and field. But he has zero interest running around in circles, he's happy as a clam in the Occult Research Club. Although he's only in the club for kicks, things get serious when a real spirit shows up at school! Life's about to get really strange in Sugisawa Town #3 High School!",
      status: .ongoing,
      tags: [
        TagModel(id: "1", title: "Action"),
        TagModel(id: "2", title: "Shounen"),
        TagModel(id: "3", title: "Supernatural")
      ], 
      authors: [AuthorModel(id: "1", name: "Akutami Gege")],
      coverInfo: "1"
    )
  }
  
  func fetchCover(mangaId: String, coverInfo: String) async throws -> Data {
    return UIImage.jujutsuCover.jpegData(compressionQuality: 1) ?? Data()
  }

}
