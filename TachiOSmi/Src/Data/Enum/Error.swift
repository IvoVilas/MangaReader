//
//  Error.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 02/03/2024.
//

import Foundation

// MARK: HTTP
enum HttpError: Error {
  case failed
  case invalidUrl
  case invalidResponse
  case responseNotOk(Int)
  case requestError(Error)

  var localizedDescription: String {
    switch self {
    case .failed:
      return "Request failed"

    case .invalidUrl:
      return "Invalid url"

    case .invalidResponse:
      return "Could not parse response"

    case .responseNotOk(let code):
      return "Got response code \(code). You may need to wait before trying again"

    case .requestError(let error):
      return "Request error: \(error.localizedDescription)"
    }
  }
}

// MARK: Parser
enum ParserError: Error {
  case parsingError
  case parameterNotFound(String)

  var localizedDescription: String {
    switch self {
    case .parsingError:
        return "Error while parsing response"

    case .parameterNotFound(let parameter):
      return "The parameter \(parameter) not found"
    }
  }
}

// MARK: Database
enum CrudError: Error {
  case requestError(Error)
  case wrongRequestType
  case mangaNotFound(id: String)
  case saveError
  case failedEntityCreation

  var localizedDescription: String {
    switch self {
    case .requestError(let error):
      return "Database request failed: \(error.localizedDescription)"

    case .wrongRequestType:
      return "Request result type did not match data type"

    case .mangaNotFound(let id):
      return "Manga not found: \(id)"

    case .saveError:
      return "Could not save database changes"

    case .failedEntityCreation:
      return "Could not create dabase entity"
    }
  }
}

// MARK: Datasource
enum DatasourceError: Error, Equatable {
  case errorParsingResponse(String)
  case networkError(String)
  case databaseError(String)
  case unexpectedError(String)
  case otherError(String)

  var localizedDescription: String {
    switch self {
    case .errorParsingResponse(let error):
      return "Error while parsing the request response\n\(error)"

    case .networkError(let error):
      return "Error during network request\n\(error)"

    case .databaseError(let error):
      return "Error during database operations\n\(error)"

    case .unexpectedError(let error):
      return "Unexpected error\n\(error)"

    case .otherError(let error):
      return error
    }
  }

  static func catchError(_ error: Error) -> DatasourceError? {
    switch error {
    case is CancellationError:
      print("MangaSearchDelegate -> Task cancelled")

    case let error as HttpError:
      return .networkError(error.localizedDescription)

    case let error as ParserError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as CrudError:
      return .errorParsingResponse(error.localizedDescription)

    case let error as DatasourceError:
      return error

    default:
      return .unexpectedError(error.localizedDescription)
    }

    return nil
  }
}

