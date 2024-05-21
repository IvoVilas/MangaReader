//
//  Moc+Extension.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 20/02/2024.
//

import Foundation
import CoreData

extension NSManagedObjectContext {

  @discardableResult public func saveIfNeeded() throws -> Bool {
    guard hasChanges else { return false }

    try save()
    
    return true
  }

}
