//
//  Moc+Extension.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

extension NSManagedObjectContext {

  enum EmptyResult<Error> {
    case success
    case failure(Error)

    var isSuccess: Bool {
      switch self {
      case .success:
        return true

      case .failure:
        return false
      }
    }

    func ingoreResult(source: String? = nil) {
      switch self {
      case .success:
        return

      case .failure(let error):
        if let source { 
          print("\(source) Error -> \(error)")
        } else {
          print("\(error)")
        }

        return
      }
    }
  }

  func saveIfNeeded(
    rollbackOnError: Bool = false
  ) -> EmptyResult<Swift.Error> {
    guard hasChanges else {
      return .success
    }

    do {
      try save()

      return .success

    } catch {
      if rollbackOnError {
        rollback()
      }

      return .failure(error)
    }
  }

}
