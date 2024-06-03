//
//  HttpClientType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 01/06/2024.
//

import Foundation

protocol HttpClientType {

  func makeJsonGetRequest(
    url: String,
    parameters: [(String, Any)]
  ) async throws -> [String: Any]

  func makeDataGetRequest(
    url: String
  ) async throws -> Data

  func makeHtmlGetRequest(
    _ url: String
  ) async throws -> String

  func makeJsonSafeGetRequest(
    url: String,
    comingFrom referer: String,
    parameters: [(String, Any)]
  ) async throws -> [String: Any]

  func makeHtmlSafeGetRequest(
    _ url: String,
    comingFrom referer: String
  ) async throws -> String

  func makeDataSafeGetRequest(
    _ url: String,
    comingFrom referer: String
  ) async throws -> Data

}
