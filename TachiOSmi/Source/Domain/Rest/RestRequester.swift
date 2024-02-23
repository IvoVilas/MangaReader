//
//  RestRequester.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 23/02/2024.
//

import Foundation

final class RestRequester {

  func makeGetRequest(
    url: String,
    parameters: [String: Any] = [:]
  ) async -> [String: Any] {
    var urlParameters = URLComponents(string: url)

    urlParameters?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }

    guard let url = urlParameters?.url else {
      print ("RestRequester -> Error creating url")

      return [:]
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let response = response as? HTTPURLResponse else {
        print("RestRequester -> Response parse error")

        return [:]
      }

      guard response.statusCode == 200 else {
        print("RestRequester -> Received response with code \(response.statusCode)")

        return [:]
      }

      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        print("RestRequester -> Error creating response json")

        return [:]
      }

      return json
    } catch {
      print("RestRequester -> Error during request \(error)")
    }

    return [:]
  }

  func makeGetRequest(
    url: String,
    parameters: [String: Any] = [:]
  ) async -> Data? {
    guard let url = URL(string: url) else {
      print ("RestRequester -> Error creating url")

      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let response = response as? HTTPURLResponse else {
        print("RestRequester -> Response parse error")

        return nil
      }

      guard response.statusCode == 200 else {
        print("RestRequester -> Received response with code \(response.statusCode)")

        return nil
      }

      return data
    } catch {
      print("RestRequester -> Error during request \(error)")
    }

    return nil
  }

}
