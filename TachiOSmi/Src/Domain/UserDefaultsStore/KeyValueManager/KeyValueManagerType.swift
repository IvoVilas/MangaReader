//
//  KeyValueManagerType.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 21/05/2024.
//

import Foundation

protocol KeyValueManagerType {
  
  func value(forKey key: String) -> Any?

  func set(value: Any?, forKey key: String)

  func removeObject(forKey defaultName: String)

}
