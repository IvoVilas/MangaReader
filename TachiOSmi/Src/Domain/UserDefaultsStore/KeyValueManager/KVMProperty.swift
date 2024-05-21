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
  private let keyValueManager: KeyValueManagerType

  private let properyValuePublisher: CurrentValueSubject<ValueType, Never>

  var publisher: AnyPublisher<ValueType, Never> {
    properyValuePublisher.eraseToAnyPublisher()
  }

  var value: ValueType {
    keyValueManager.value(forKey: key) as? ValueType ?? defaultValue
  }

  init(
    key: String,
    defaultValue: ValueType,
    keyValueManager: KeyValueManagerType
  ) {
    self.key = key
    self.defaultValue = defaultValue
    self.keyValueManager = keyValueManager

    properyValuePublisher = CurrentValueSubject(
      keyValueManager.value(forKey: key) as? ValueType ?? defaultValue
    )
  }

  func setValue(_ value: ValueType) {
    keyValueManager.set(value: value, forKey: key)

    properyValuePublisher.value = value
  }

  func destroy() {
    keyValueManager.removeObject(forKey: key)
  }

}
