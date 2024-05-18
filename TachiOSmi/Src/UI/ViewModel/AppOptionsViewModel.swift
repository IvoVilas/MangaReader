//
//  AppOptionsViewModel.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 18/05/2024.
//

import Foundation
import SwiftUI

final class AppOptionsViewModel: ObservableObject {

  @Published var options: [Option]

  init() {
    options = [
      .themeSelection(
        OptionSelectionViewModel(
          id: "select_app_theme",
          options: [.system, .light, .dark] ,
          selectedOption: .system,
          title: "Theme",
          icon: .system("paintpalette"),
          iconColor: .indigo
        )
      ),
      .readerDirectionSelection(
        OptionSelectionViewModel(
          id: "select_default_reader_direction",
          options: [.leftToRight, .upToDown],
          selectedOption: .leftToRight,
          title: "Default reader direction",
          icon: .system("iphone.gen3.badge.play"),
          iconColor: .teal
        )
      ),
      .toggle(
        OptionToggleViewModel(
          id: "toggle_data_saving",
          value: false,
          title: "Data saving",
          icon: .system("exclamationmark.icloud"),
          iconColorOn: .green,
          iconColorOff: .pink
        )
      ),
      .action(
        OptionActionViewModel(
          id: "action_clean_database",
          title: "Clean database",
          description: "Delete all unsaved entites",
          icon: .asset(.database),
          iconColor: .orange,
          actionTitle: "Delete entities",
          actionMessage: "App will keep all data about mangas in you library"
        ) {
          // TODO: Do something
        }
      )
    ]
  }

}

// MARK: Option enum
extension AppOptionsViewModel {

  enum Option: Identifiable {
    case themeSelection(OptionSelectionViewModel<ThemePalette>)
    case readerDirectionSelection(OptionSelectionViewModel<ReadingDirection>)
    case toggle(OptionToggleViewModel)
    case action(OptionActionViewModel)

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
  }

  func callAction() {
    action()
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
