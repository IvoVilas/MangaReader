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

    case libraryLayout(CollectionLayout)
    case libraryGridSize(Int)

    case searchLayout(CollectionLayout)
  }

  private let appThemeProperty: KVMProperty<Int16>
  private let defaultDirectionProperty: KVMProperty<Int16>
  private let isDataSavingOnProperty: KVMProperty<Bool>

  private let libraryLayoutProperty: KVMProperty<Int16>
  private let libraryGridSizeProperty: KVMProperty<Int>

  private let searchLayoutProperty: KVMProperty<Int16>

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

  var libraryLayoutPublisher: AnyPublisher<CollectionLayout, Never> {
    libraryLayoutProperty.publisher
      .map { .safeInit(from: $0) }
      .eraseToAnyPublisher()
  }

  var libraryGridSizePublisher: AnyPublisher<Int, Never> {
    libraryGridSizeProperty.publisher
  }

  var searchLayoutPublisher: AnyPublisher<CollectionLayout, Never> {
    searchLayoutProperty.publisher
      .map { .safeInit(from: $0) }
      .eraseToAnyPublisher()
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

  var libraryLayout: CollectionLayout {
    return .safeInit(from: libraryLayoutProperty.value)
  }

  var libraryGridSize: Int {
    return libraryGridSizeProperty.value
  }


  var searchLayout: CollectionLayout {
    return .safeInit(from: searchLayoutProperty.value)
  }

  init(
    keyValueManager: KeyValueManagerType
  ) {
    appThemeProperty = KVMProperty(
      key: "app_theme",
      defaultValue: ThemePalette.system.id,
      keyValueManager: keyValueManager
    )

    defaultDirectionProperty = KVMProperty(
      key: "default_reading_direction",
      defaultValue: ReadingDirection.leftToRight.id,
      keyValueManager: keyValueManager
    )

    isDataSavingOnProperty = KVMProperty(
      key: "is_data_saving_on",
      defaultValue: false,
      keyValueManager: keyValueManager
    )

    libraryLayoutProperty = KVMProperty(
      key: "library_layout",
      defaultValue: CollectionLayout.normal.id,
      keyValueManager: keyValueManager
    )

    libraryGridSizeProperty = KVMProperty(
      key: "library_grid_size",
      defaultValue: 3,
      keyValueManager: keyValueManager
    )

    searchLayoutProperty = KVMProperty(
      key: "library_layout",
      defaultValue: CollectionLayout.normal.id,
      keyValueManager: keyValueManager
    )
  }

  func changeProperty(_ property: Property) {
    switch property {
    case .appTheme(let theme):
      appThemeProperty.setValue(theme.id)

    case .defaultDirection(let direction):
      defaultDirectionProperty.setValue(direction.id)

    case .isDataSavingOn(let value):
      isDataSavingOnProperty.setValue(value)

    case .libraryLayout(let layout):
      libraryLayoutProperty.setValue(layout.id)

    case .libraryGridSize(let size):
      libraryGridSizeProperty.setValue(size)

    case .searchLayout(let layout):
      searchLayoutProperty.setValue(layout.id)
    }
  }

}
