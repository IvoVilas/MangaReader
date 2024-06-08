//
//  SelectionSheet.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 08/06/2024.
//

import SwiftUI

struct SelectionSheet<OptionType: Hashable>: View {

  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var scheme

  let title: String
  @Binding var selectedOptions: [Option]
  @Binding var options: [Option]
  @State var settings: Settings

  private init(
    title: String,
    selectedOption: Binding<[Option]>,
    options: Binding<[OptionType]>,
    idBuilder: @escaping (OptionType) -> String,
    nameBuilder: @escaping (OptionType) -> String,
    settings: Settings
  ) {
    self.title = title
    self.settings = settings
    self._selectedOptions = selectedOption

    self._options = Binding<[Option]> {
      options.wrappedValue.map {
        Option(
          id: idBuilder($0),
          name: nameBuilder($0),
          option: $0
        )
      }
    } set: { newOptions in
      options.wrappedValue = newOptions.map { $0.option }
    }
  }

  init(
    title: String,
    selectedOption: Binding<[OptionType]>,
    options: Binding<[OptionType]>,
    idBuilder: @escaping (OptionType) -> String,
    nameBuilder: @escaping (OptionType) -> String,
    mandatory: Bool = true
  ) {
    let selected = Binding<[Option]> {
      selectedOption.wrappedValue.map {
        Option(
          id: idBuilder($0),
          name: nameBuilder($0),
          option: $0
        )
      }
    } set: { newOptions in
      selectedOption.wrappedValue = newOptions.map { $0.option }
    }

    self.init(
      title: title,
      selectedOption: selected,
      options: options,
      idBuilder: idBuilder,
      nameBuilder: nameBuilder,
      settings: Settings(
        multiSelection: true,
        closeOnSelection: false,
        mandatory: mandatory
      )
    )
  }

  init(
    title: String,
    selectedOptions: Binding<OptionType?>,
    options: Binding<[OptionType]>,
    idBuilder: @escaping (OptionType) -> String,
    nameBuilder: @escaping (OptionType) -> String,
    closeOnSelection: Bool = false,
    mandatory: Bool = true
  ) {
    let selected = Binding<[Option]> {
      guard let option = selectedOptions.wrappedValue else {
        return []
      }

      return [
        Option(
          id: idBuilder(option),
          name: nameBuilder(option),
          option: option
        )
      ]
    } set: { newOptions in
      selectedOptions.wrappedValue = newOptions.first.map { $0.option }
    }

    self.init(
      title: title,
      selectedOption: selected,
      options: options,
      idBuilder: idBuilder,
      nameBuilder: nameBuilder,
      settings: Settings(
        multiSelection: false,
        closeOnSelection: closeOnSelection,
        mandatory: mandatory
      )
    )
  }

  init(
    title: String,
    selectedOption: Binding<OptionType>,
    options: Binding<[OptionType]>,
    idBuilder: @escaping (OptionType) -> String,
    nameBuilder: @escaping (OptionType) -> String,
    closeOnSelection: Bool = false,
    mandatory: Bool = true
  ) {
    let selected = Binding<[Option]> {
      return [
        Option(
          id: idBuilder(selectedOption.wrappedValue),
          name: nameBuilder(selectedOption.wrappedValue),
          option: selectedOption.wrappedValue
        )
      ]
    } set: { newOptions in
      if let newOption = newOptions.first {
        selectedOption.wrappedValue = newOption.option
      }
    }

    self.init(
      title: title,
      selectedOption: selected,
      options: options,
      idBuilder: idBuilder,
      nameBuilder: nameBuilder,
      settings: Settings(
        multiSelection: false,
        closeOnSelection: closeOnSelection,
        mandatory: mandatory
      )
    )
  }

  var body: some View {
    List {
      Section {
        ForEach(options) { option in
          Button {
            selectOption(option)

            if !settings.multiSelection && settings.closeOnSelection {
              dismiss()
            }
          } label: {
            HStack(spacing: 0) {
              Text(option.name)
                .foregroundStyle(scheme.foregroundColor)

              Spacer()

              Image(systemName: "checkmark")
                .foregroundStyle(.green)
                .font(.body.weight(.semibold))
                .opacity(isOptionSelected(option) ? 1 : 0)
            }
          }
        }
      } header: {
        Text(title)
      }
    }
    .listStyle(.automatic)
  }

  private func selectOption(_ option: Option) {
    if settings.multiSelection {
      if isOptionSelected(option) {
        if !settings.mandatory || !selectedOptions.filter({ $0.id != option.id }).isEmpty {
          selectedOptions.removeAll { $0.id == option.id }
        }
      } else {
        selectedOptions.append(option)
      }
    } else {
      selectedOptions = !isOptionSelected(option) || settings.mandatory ? [option] : []
    }
  }

  private func isOptionSelected(_ option: Option) -> Bool {
    selectedOptions.contains { $0.id == option.id }
  }

  struct Settings {
    let multiSelection: Bool
    let closeOnSelection: Bool
    let mandatory: Bool
  }

  struct Option: Identifiable {
    let id: String
    let name: String
    let option: OptionType
  }

}

private struct Preview_Content_Single: View {

  @State var selectedOption: String?
  @State var options: [String]
  @State private var showingSelection = false

  var body: some View {
    Button { showingSelection.toggle() } label: {
      Text(selectedOption ?? "None")
    }
    .sheet(isPresented: $showingSelection) {
      SelectionSheet(
        title: "Select one option",
        selectedOptions: $selectedOption,
        options: $options,
        idBuilder: { $0 },
        nameBuilder: { $0 }
      )
      .presentationDetents([.medium])
    }
  }

}

private struct Preview_Content_Multiple: View {

  @State var selectedOption: [String]
  @State var options: [String]
  @State private var showingSelection = false

  var body: some View {
    Button { showingSelection.toggle() } label: {
      Text( selectedOption.isEmpty ? "None" :
        selectedOption.reduce(into: "") { $0.append("\($1) ") }
      )
    }
    .sheet(isPresented: $showingSelection) {
      SelectionSheet(
        title: "Select each that applies",
        selectedOption: $selectedOption,
        options: $options,
        idBuilder: { $0 },
        nameBuilder: { $0 }
      )
      .presentationDetents([.medium])
    }
  }

}

#Preview("Single Selection") {
  Preview_Content_Single(
    selectedOption: nil,
    options: ["Yesterday", "Today", "Tommorrow"]
  )
}

#Preview("Multiple Selection") {
  Preview_Content_Multiple(
    selectedOption: [],
    options: ["Yesterday", "Today", "Tommorrow"]
  )
}

