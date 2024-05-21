//
//  UserDefaultsManager.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 21/05/2024.
//

import Foundation

final class UserDefaultsManager: KeyValueManagerType {

  private let userDefaults: UserDefaults

  init(
    userDefaults: UserDefaults = .standard
  ) {
    self.userDefaults = userDefaults
  }

  func value(forKey key: String) -> Any? {
    return userDefaults.object(forKey: key)
  }

  func set(value: Any?, forKey key: String) {
    userDefaults.setValue(value, forKey: key)
  }

  func removeObject(forKey defaultName: String) {
    userDefaults.removeObject(forKey: defaultName)
  }

}
