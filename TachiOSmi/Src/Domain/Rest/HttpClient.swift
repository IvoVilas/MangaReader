//
//  HttpClient.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 23/02/2024.
//

import Foundation

final class HttpClient {

  func makeJsonGetRequest(
    url: String,
    parameters: [(String, Any)] = []
  ) async throws -> [String: Any] {
    var urlParameters = URLComponents(string: url)

    urlParameters?.queryItems = parameters.map { URLQueryItem(name: $0.0, value: String(describing: $0.1)) }

    guard let url = urlParameters?.url else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard
        let response = response as? HTTPURLResponse,
        response.statusCode == 200
      else {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1

        throw HttpError.responseNotOk(code)
      }

      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw HttpError.invalidResponse
      }

      return json
    } catch let error as URLError {
      if error.code == URLError.cancelled {
        throw CancellationError()
      } else {
        throw HttpError.requestError(error)
      }
    } catch let error as HttpError {
      throw error
    } catch {
      throw HttpError.requestError(error)
    }
  }

  func makeDataGetRequest(
    url: String,
    parameters: [String: Any] = [:]
  ) async throws -> Data {
    guard let url = URL(string: url) else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard
        let response = response as? HTTPURLResponse,
        response.statusCode == 200
      else {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1

        throw HttpError.responseNotOk(code)
      }

      return data
    } catch let error as URLError {
      if error.code == URLError.cancelled {
        throw CancellationError()
      } else {
        throw HttpError.requestError(error)
      }
    } catch let error as HttpError {
      throw error
    } catch {
      throw HttpError.requestError(error)
    }
  }

}
