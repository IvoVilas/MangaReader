//
//  BackgroundHttpClient.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 01/06/2024.
//

import Foundation
import Alamofire

// TODO: Try to use background session
final class BackgroundHttpClient: HttpClientType {

  private let session: URLSession

  init(
    for task: AppTask
  ) {
    let config = URLSessionConfiguration.default

    config.sessionSendsLaunchEvents = true
    config.httpCookieStorage = .shared
    config.httpCookieAcceptPolicy = .always

    session = URLSession(configuration: config)
  }

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
    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36", forHTTPHeaderField: "User-Agent")
    request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")

    do {
      let result = await withTaskCancellationHandler {
        try? await session.data(for: request)
      } onCancel: { [request] in
        print("BackgroundHttpClient - Request \(String(describing: request.url)) cancelled")
      }

      guard let result else {
        throw HttpError.failed
      }

      let (data, response) = result

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
    url: String
  ) async throws -> Data {
    guard let url = URL(string: url) else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36", forHTTPHeaderField: "User-Agent")
    request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")

    do {
      let result = await withTaskCancellationHandler {
        try? await session.data(for: request)
      } onCancel: { [request] in
        print("BackgroundHttpClient - Request \(String(describing: request.url)) cancelled")
      }

      guard let result else {
        throw HttpError.failed
      }

      let (data, response) = result

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

  func makeHtmlGetRequest(
    _ url: String
  ) async throws -> String {
    guard let url = URL(string: url) else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36", forHTTPHeaderField: "User-Agent")
    request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")

    do {
      let result = await withTaskCancellationHandler {
        try? await session.data(for: request)
      } onCancel: { [request] in
        print("BackgroundHttpClient - Request \(String(describing: request.url)) cancelled")
      }

      guard let result else {
        throw HttpError.failed
      }

      let (data, response) = result

      guard
        let response = response as? HTTPURLResponse,
        response.statusCode == 200
      else {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1

        throw HttpError.responseNotOk(code)
      }

      guard let html = String(data: data, encoding: .utf8) else {
        throw HttpError.invalidResponse
      }

      return html
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

extension BackgroundHttpClient {

  func makeJsonSafeGetRequest(
    url: String,
    comingFrom referer: String,
    parameters: [(String, Any)] = []
  ) async throws -> [String: Any] {
    var urlParameters = URLComponents(string: url)

    if !parameters.isEmpty {
      urlParameters?.queryItems = parameters.map { URLQueryItem(name: $0.0, value: String(describing: $0.1)) }
    }

    guard let url = urlParameters?.url else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
    request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.setValue(referer, forHTTPHeaderField: "Referer")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
    request.setValue(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      forHTTPHeaderField: "User-Agent"
    )

    do {
      logRequest(request: request)

      let result = await withTaskCancellationHandler {
        try? await session.data(for: request)
      } onCancel: { [request] in
        print("BackgroundHttpClient - Request \(String(describing: request.url)) cancelled")
      }

      guard let result else {
        throw HttpError.failed
      }

      let (data, response) = result

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

  func makeHtmlSafeGetRequest(
    _ url: String,
    comingFrom referer: String
  ) async throws -> String {
    guard let url = URL(string: url) else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
    request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.setValue(referer, forHTTPHeaderField: "Referer")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
    request.setValue(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      forHTTPHeaderField: "User-Agent"
    )

    if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
        let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)
        request.allHTTPHeaderFields?.merge(cookieHeader) { (current, _) in current }
    }

    do {
      logRequest(request: request)

      let result = await withTaskCancellationHandler {
        try? await session.data(for: request)
      } onCancel: { [request] in
        print("BackgroundHttpClient - Request \(String(describing: request.url)) cancelled")
      }

      guard let result else {
        throw HttpError.failed
      }

      let (data, response) = result

      guard
        let response = response as? HTTPURLResponse,
        response.statusCode == 200
      else {
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1

        throw HttpError.responseNotOk(code)
      }

      guard let html = String(data: data, encoding: .utf8) else {
        throw HttpError.invalidResponse
      }

      return html
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

  func makeDataSafeGetRequest(
    _ url: String,
    comingFrom referer: String,
    addRefererCookies: Bool
  ) async throws -> Data {
    guard let url = URL(string: url) else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)

    request.setValue(referer, forHTTPHeaderField: "Referer")
    request.setValue("image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
    request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
    request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
    request.setValue(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      forHTTPHeaderField: "User-Agent"
    )

    if
      addRefererCookies,
      let refererUrl = URL(string: referer),
      let cookies = HTTPCookieStorage.shared.cookies(for: refererUrl)
    {
      let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)
      request.allHTTPHeaderFields?.merge(cookieHeader) { (current, _) in current }
    }

    do {
      let result = await withTaskCancellationHandler {
        try? await session.data(for: request)
      } onCancel: { [request] in
        print("BackgroundHttpClient - Request \(String(describing: request.url)) cancelled")
      }

      guard let result else {
        throw HttpError.failed
      }

      let (data, response) = result

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

extension BackgroundHttpClient {

  private func logRequest(
    request: URLRequest
  ) {
    print()
    print("BackgroundHttpClient -> Sending request to: \(request.url?.absoluteString ?? "Url not found")")
    print("  BackgroundHttpClient -> Referer: \(request.value(forHTTPHeaderField: "Referer") ?? "Empty")")
    print("  BackgroundHttpClient -> Has cookies: \(request.value(forHTTPHeaderField: "Cookie")?.isEmpty == false)")
    print()
  }

}
