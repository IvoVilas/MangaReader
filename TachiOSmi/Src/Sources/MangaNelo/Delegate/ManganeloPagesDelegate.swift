//
//  ManganeloPagesDelegate.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

// REDO
import Foundation

final class ManganeloPagesDelegate: PagesDelegateType {

  private let httpClient: HttpClient

  init(
    httpClient: HttpClient
  ) {
    self.httpClient = httpClient
  }

  func fetchDownloadInfo(
    chapterId: String
  ) async throws -> MangadexChapterDownloadInfo {
    throw DatasourceError.otherError("TODO")
  }

  func fetchPage(
    index: Int,
    info: MangadexChapterDownloadInfo
  ) async throws -> Data {
    throw DatasourceError.otherError("TODO")
  }

  func fetchPage(
    _ url: String
  ) async throws -> Data {
    throw DatasourceError.otherError("TODO")
  }

  func buildUrl(
    index: Int,
    info: MangadexChapterDownloadInfo
  ) throws -> String {
    throw DatasourceError.otherError("TODO")
  }
  
}
