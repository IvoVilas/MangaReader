//
//  KVMProperty.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 18/05/2024.
//

import Foundation
import Combine

struct KVMProperty<ValueType> {

  private let key: String
  private let defaultValue: ValueType
  private let userDefaults: UserDefaults

  private let properyValuePublisher: CurrentValueSubject<ValueType, Never>

  var publisher: AnyPublisher<ValueType, Never> {
    properyValuePublisher.eraseToAnyPublisher()
  }

  var value: ValueType {
    userDefaults.object(forKey: key) as? ValueType ?? defaultValue
  }

  init(
    key: String,
    defaultValue: ValueType,
    userDefaults: UserDefaults = .standard
  ) {
    self.key = key
    self.defaultValue = defaultValue
    self.userDefaults = userDefaults

    properyValuePublisher = CurrentValueSubject(
      userDefaults.object(forKey: key) as? ValueType ?? defaultValue
    )
  }

  func setValue(_ value: ValueType) {
    userDefaults.setValue(value, forKey: key)

    properyValuePublisher.value = value
  }

  func destroy() {
    userDefaults.removeObject(forKey: key)
  }

}
