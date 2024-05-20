//
//  AppOptionsViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 18/05/2024.
//

import Foundation
import SwiftUI
import Combine

final class AppOptionsViewModel: ObservableObject {

  @Published var options: [Option]
  @Published var isLoading: Bool
  @Published var error: DatasourceError?
  @Published var info: String?

  private let store: AppOptionsStore
  private let databaseManager: DatabaseManager

  private var observers = Set<AnyCancellable>()

  init(
    store: AppOptionsStore,
    databaseManager: DatabaseManager
  ) {
    self.store = store
    self.databaseManager = databaseManager

    isLoading = false
    options = []
    info = nil

    setupOptions()
  }

  private func setupOptions() {
    let themeSelectionViewModel = OptionSelectionViewModel(
      id: "select_app_theme",
      options: [ThemePalette.system, .light, .dark] ,
      selectedOption: store.appTheme,
      title: "Theme",
      icon: .system("paintpalette"),
      iconColor: .indigo
    )

    let readerDirectionSelectionViewModel = OptionSelectionViewModel(
      id: "select_default_reader_direction",
      options: [ReadingDirection.leftToRight, .upToDown],
      selectedOption: store.defaultDirection,
      title: "Default direction",
      icon: .system("iphone.gen3.badge.play"),
      iconColor: .teal
    )

    let dataSavingToggleViewModel = OptionToggleViewModel(
      id: "toggle_data_saving",
      value: store.isDataSavingOn,
      title: "Data saving",
      icon: .system("exclamationmark.icloud"),
      iconColorOn: .green,
      iconColorOff: .pink
    )

    options = [
      .themeSelection(themeSelectionViewModel),
      .readerDirectionSelection(readerDirectionSelectionViewModel),
      .toggle(dataSavingToggleViewModel),
      .action(
        OptionActionViewModel(
          id: "action_clean_database",
          title: "Clean database",
          description: "Delete all unsaved entites",
          icon: .asset(.database),
          iconColor: .orange,
          actionTitle: "Delete entities",
          actionMessage: "App will keep all data about mangas in you library",
          action: { [weak self] in
            guard let self else { return }

            self.isLoading = true

            switch self.databaseManager.cleanDatabase() {
            case .success((let mangaCount, let coverCount)):
              self.info = "Deleted \(mangaCount) manga(s) and \(coverCount) cover(s)"

            case .failure(let cause):
              self.error = cause
            }

            self.isLoading = false
          }
        )
      ),
      .share(
        OptionShareViewModel(
          id: "action_dump_database",
          title: "Dump database",
          description: "Dump database data",
          icon: .system("square.and.arrow.down"),
          iconColor: .green,
          buildFile: { [weak self] in
            guard let self else { return nil }

            self.isLoading = true

            let result = self.databaseManager.dumpDatabase()

            self.isLoading = false

            switch result {
            case .success(let url):
              return url

            case .failure(let error):
              self.error = error
            }

            return nil
          }
        )
      )
    ]

    themeSelectionViewModel.$selectedOption
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.store.changeProperty(.appTheme($0))}
      .store(in: &observers)

    readerDirectionSelectionViewModel.$selectedOption
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.store.changeProperty(.defaultDirection($0))}
      .store(in: &observers)

    dataSavingToggleViewModel.$value
      .receive(on: DispatchQueue.main)
      .sink { [weak self] in self?.store.changeProperty(.isDataSavingOn($0))}
      .store(in: &observers)
  }

}

// MARK: Option enum
extension AppOptionsViewModel {

  enum Option: Identifiable {
    case themeSelection(OptionSelectionViewModel<ThemePalette>)
    case readerDirectionSelection(OptionSelectionViewModel<ReadingDirection>)
    case toggle(OptionToggleViewModel)
    case action(OptionActionViewModel)
    case share(OptionShareViewModel)

    var id: String {
      switch self {
      case .themeSelection(let viewModel):
        return viewModel.id

      case .readerDirectionSelection(let viewModel):
        return viewModel.id

      case .toggle(let viewModel):
        return viewModel.id

      case .action(let viewModel):
        return viewModel.id

      case .share(let viewModel):
        return viewModel.id
      }
    }

  }

}

// MARK: OptionSelectionViewModel
final class OptionSelectionViewModel<T: Hashable & CustomStringConvertible>: ObservableObject {

  @Published var options: [T]
  @Published var selectedOption: T
  @Published var title: String
  @Published var icon: IconSource
  @Published var iconColor: Color

  let id: String

  init(
    id: String,
    options: [T],
    selectedOption: T,
    title: String,
    icon: IconSource,
    iconColor: Color
  ) {
    self.id = id
    self.options = options
    self.selectedOption = selectedOption
    self.title = title
    self.icon = icon
    self.iconColor = iconColor
  }

}

// MARK: OptionToggleViewModel
final class OptionToggleViewModel: ObservableObject {

  @Published var value: Bool
  @Published var title: String
  @Published var icon: IconSource
  @Published var iconColorOn: Color
  @Published var iconColorOff: Color

  let id: String

  init(
    id: String,
    value: Bool,
    title: String,
    icon: IconSource,
    iconColorOn: Color,
    iconColorOff: Color
  ) {
    self.id = id
    self.value = value
    self.title = title
    self.icon = icon
    self.iconColorOn = iconColorOn
    self.iconColorOff = iconColorOff
  }

}

// MARK: OptionActionViewModel
final class OptionActionViewModel: ObservableObject {

  @Published var title: String
  @Published var description: String
  @Published var icon: IconSource
  @Published var iconColor: Color
  @Published var actionTitle: String
  @Published var actionMessage: String
  @Published var showingDialog: Bool

  let id: String

  private let action: () -> Void

  init(
    id: String,
    title: String,
    description: String,
    icon: IconSource,
    iconColor: Color,
    actionTitle: String,
    actionMessage: String,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.icon = icon
    self.iconColor = iconColor
    self.actionTitle = actionTitle
    self.actionMessage = actionMessage
    self.action = action
    self.showingDialog = false
  }

  func callAction() {
    action()
  }

}

// TODO: Remove file after sharing
final class OptionShareViewModel: ObservableObject {

  @Published var title: String
  @Published var description: String
  @Published var icon: IconSource
  @Published var iconColor: Color
  @Published var fileUrl: URL?
  @Published var showingShare: Bool

  let id: String

  private let buildFile: () -> URL?

  init(
    id: String,
    title: String,
    description: String,
    icon: IconSource,
    iconColor: Color,
    buildFile: @escaping () -> URL?
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.icon = icon
    self.iconColor = iconColor
    self.buildFile = buildFile
    self.showingShare = false
  }

  func share() {
    fileUrl = buildFile()
    showingShare = true
  }

  func deleteFile() {
    guard let fileUrl else {
      print("Database dump file not found")

      return
    }

    do {
      try FileManager.default.removeItem(at: fileUrl)

      self.fileUrl = nil

      print("Database dump file deleted.")
    } catch {
      print("Error deleting temporary file: \(error)")
    }
  }

}

// MARK: Extensions
extension ThemePalette: CustomStringConvertible {

  var description: String {
    switch self {
    case .system:
      return "System"

    case .dark:
      return "Dark"

    case .light:
      return "Light"
    }
  }

}

extension ReadingDirection: CustomStringConvertible {

  var description: String {
    switch self {
    case .leftToRight:
      return "Left to right"

    case .upToDown:
      return "Long strip"
    }
  }

}
