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

  func makeDataSafeGetRequest(
    _ url: String,
    comingFrom referer: String
  ) async throws -> Data {
    guard let url = URL(string: url) else { throw HttpError.invalidUrl }

    var request = URLRequest(url: url)

    request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36", forHTTPHeaderField: "User-Agent")
    request.setValue(referer, forHTTPHeaderField: "Referer")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
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

}

// MARK: Delegate
class BackgroundSessionDelegate: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {

  var downloadCompletionHandler: ((URL) -> Void)?

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    downloadCompletionHandler?(location)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      print("BackgroundHttpClient - Download task completed with error: \(error.localizedDescription)")
    } else {
      print("BackgroundHttpClient - Download task completed successfully.")
    }
  }

}
