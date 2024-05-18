//
//  ValuePicker.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 18/05/2024.
//

import SwiftUI

public struct ValuePicker<SelectionValue: Hashable, Content: View, Label: View>: View {

  private let title: String
  private let selection: Binding<SelectionValue>
  private let content: Content
  private let label: Label

  public init(
    _ title: String,
    selection: Binding<SelectionValue>,
    @ViewBuilder content: () -> Content,
    @ViewBuilder label: () -> Label
  ) {
    self.title = title
    self.selection = selection
    self.content = content()
    self.label = label()
  }

  public var body: some View {
    NavigationLink {
      List {
        _VariadicView.Tree(ValuePickerOptions(selectedValue: selection)) {
          content
        }
      }
      .navigationTitle(title)
    } label: {
      label
    }
  }

}

private struct ValuePickerOptions<Value: Hashable>: _VariadicView.MultiViewRoot {

  private let selectedValue: Binding<Value>

  init(selectedValue: Binding<Value>) {
    self.selectedValue = selectedValue
  }

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    Section {
      ForEach(children) { child in
        ValuePickerOption(
          selectedValue: selectedValue,
          value: child[CustomTagValueTraitKey<Value>.self]
        ) {
          child
        }
      }
    }
  }

}

private struct ValuePickerOption<Content: View, Value: Hashable>: View {

  @Environment(\.dismiss) private var dismiss

  private let selectedValue: Binding<Value>
  private let value: Value?
  private let content: Content

  init(
    selectedValue: Binding<Value>,
    value: CustomTagValueTraitKey<Value>.Value,
    @ViewBuilder _ content: () -> Content
  ) {
    self.selectedValue = selectedValue
    self.value = if case .tagged(let tag) = value {
      tag
    } else {
      nil
    }
    self.content = content()
  }

  var body: some View {
    Button(
      action: {
        if let value {
          selectedValue.wrappedValue = value
        }
        dismiss()
      },
      label: {
        HStack {
          content
            .tint(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)

          if isSelected {
            Image(systemName: "checkmark")
              .foregroundStyle(.tint)
              .font(.body.weight(.semibold))
              .accessibilityHidden(true)
          }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
      }
    )
  }

  private var isSelected: Bool {
    selectedValue.wrappedValue == value
  }

}

extension View {

  public func pickerTag<V: Hashable>(_ tag: V) -> some View {
    _trait(CustomTagValueTraitKey<V>.self, .tagged(tag))
  }

}

private struct CustomTagValueTraitKey<V: Hashable>: _ViewTraitKey {

  enum Value {
    case untagged
    case tagged(V)
  }

  static var defaultValue: CustomTagValueTraitKey<V>.Value {
    .untagged
  }

}

private struct PreviewContent: View {

  @State private var selection = "John"

  var body: some View {
    NavigationStack {
      List {
        ValuePicker("Name", selection: $selection) {
          ForEach(["John", "Jean", "Juan"], id: \.self) { name in
            Text(name)
              .pickerTag(name)
          }
        } label: {
          VStack {
            Text("Name")
              .font(.footnote.weight(.medium))
              .foregroundStyle(.secondary)

            Text(selection)
          }
        }
      }
      .navigationTitle("Custom Picker")
    }
  }

}

#Preview {
  PreviewContent()
}
