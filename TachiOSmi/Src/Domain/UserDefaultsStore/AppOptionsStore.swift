//
//  AppOptionsStore.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 18/05/2024.
//

import Foundation
import Combine

// TODO: Make an inMemory version to use in preview
final class AppOptionsStore {

  enum Property {
    case appTheme(ThemePalette)
    case defaultDirection(ReadingDirection)
    case isDataSavingOn(Bool)
  }

  private let appThemeProperty: KVMProperty<Int16>
  private let defaultDirectionProperty: KVMProperty<Int16>
  private let isDataSavingOnProperty: KVMProperty<Bool>

  var appThemePublisher: AnyPublisher<ThemePalette, Never> {
    appThemeProperty.publisher
      .map { .safeInit(from: $0) }
      .eraseToAnyPublisher()
  }

  var defaultDirectionPublisher: AnyPublisher<ReadingDirection, Never> {
    defaultDirectionProperty.publisher
      .map { .safeInit(from: $0) }
      .eraseToAnyPublisher()
  }

  var isDataSavingOnPublisher: AnyPublisher<Bool, Never> {
    isDataSavingOnProperty.publisher
  }

  var appTheme: ThemePalette {
    return .safeInit(from: appThemeProperty.value)
  }

  var defaultDirection: ReadingDirection {
    return .safeInit(from: defaultDirectionProperty.value)
  }

  var isDataSavingOn: Bool {
    return isDataSavingOnProperty.value
  }

  init() {
    appThemeProperty = KVMProperty(key: "app_theme", defaultValue: ThemePalette.system.id)
    defaultDirectionProperty = KVMProperty(key: "default_reading_direction", defaultValue: ReadingDirection.leftToRight.id)
    isDataSavingOnProperty = KVMProperty(key: "is_data_saving_on", defaultValue: false)
  }

  func changeProperty(_ property: Property) {
    switch property {
    case .appTheme(let theme):
      appThemeProperty.setValue(theme.id)

    case .defaultDirection(let direction):
      defaultDirectionProperty.setValue(direction.id)

    case .isDataSavingOn(let value):
      isDataSavingOnProperty.setValue(value)
    }
  }

}
