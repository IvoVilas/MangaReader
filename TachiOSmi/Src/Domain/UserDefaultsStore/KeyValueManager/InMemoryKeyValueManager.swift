//
//  InMemoryKeyValueManager.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 21/05/2024.
//

import Foundation

final class InMemoryKeyValueManager: KeyValueManagerType {

  private var values = [String: Any]()

  func value(forKey key: String) -> Any? {
    return values[key]
  }
  
  func set(value: Any?, forKey key: String) {
    if let value = value {
      values[key] = value
    } else {
      values.removeValue(forKey: key)
    }
  }
  
  func removeObject(forKey key: String) {
    values.removeValue(forKey: key)
  }
  

}
