//
//  MoreOptionsView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 17/05/2024.
//

import SwiftUI

struct AppOptionsView: View {

  @Environment(\.colorScheme) private var scheme

  @StateObject private var viewModel: AppOptionsViewModel
  @State private var showingDialog = false

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: 16, alignment: .top),
    count: 3
  )

  init(
    store: AppOptionsStore
  ) {
    _viewModel = StateObject(
      wrappedValue: AppOptionsViewModel(
        store: store
      )
    )
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("Options")
        .foregroundStyle(scheme.foregroundColor)
        .font(.title)

      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(viewModel.options) { option in
            switch option {
            case .themeSelection(let viewModel):
              OptionSelectionView(viewModel: viewModel)

            case .readerDirectionSelection(let viewModel):
              OptionSelectionView(viewModel: viewModel)

            case .toggle(let viewModel):
              OptionToggleView(viewModel: viewModel)

            case .action(let viewModel):
              OptionActionView(viewModel: viewModel, showingDialog: $showingDialog)

            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .background(scheme.backgroundColor)
  }

}

// MARK: Selection view
private struct OptionSelectionView<T: Hashable & CustomStringConvertible>: View {

  @ObservedObject var viewModel: OptionSelectionViewModel<T>

  var body: some View {
    ValuePicker(viewModel.title, selection: $viewModel.selectedOption) {
      ForEach(viewModel.options, id: \.self.description) { option in
        Text(option.description)
          .pickerTag(option)
      }
    } label: {
      VStack(spacing: 0) {
        viewModel.icon.image()
          .resizable()
          .scaledToFit()
          .foregroundStyle(viewModel.iconColor)
          .frame(width: 24, height: 24)

        Spacer().frame(height: 8)

        Text(viewModel.title)
          .foregroundStyle(.black)
          .font(.caption)
          .frame(maxWidth: .infinity)

        Spacer().frame(height: 4)

        Text(String(describing: viewModel.selectedOption))
          .foregroundStyle(.blue)
          .font(.caption2)

        Spacer().frame(idealHeight: 16, maxHeight: 16)

        Image(.expandMore)
          .foregroundStyle(.black)
      }
      .padding(.vertical)
      .padding(.horizontal, 4)
      .background(Color(uiColor: .systemFill))
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
  }
}

// MARK: Toggle view
private struct OptionToggleView: View {

  @ObservedObject var viewModel: OptionToggleViewModel

  var body: some View {
    Button {
      viewModel.value.toggle()
    } label: {
      VStack(spacing: 0) {
        viewModel.icon.image()
          .resizable()
          .scaledToFit()
          .foregroundStyle(viewModel.value ? viewModel.iconColorOn : viewModel.iconColorOff)
          .frame(width: 24, height: 24)
          .animation(.bouncy, value: viewModel.value)

        Spacer().frame(height: 8)

        Text(viewModel.title)
          .foregroundStyle(.black)
          .font(.caption)
          .frame(maxWidth: .infinity)

        Spacer().frame(height: 4)

        Text(viewModel.value ? "On" : "Off")
          .foregroundStyle(.blue)
          .font(.caption2)
          .animation(.bouncy, value: viewModel.value)

        Spacer().frame(maxHeight: 16)

        Toggle(isOn: $viewModel.value) { }
          .toggleStyle(MyToggleStyle())
      }
      .padding(.vertical)
      .padding(.horizontal, 4)
      .background(Color(uiColor: .systemFill))
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(NoTapAnimationStyle())
  }

}

// MARK: Action view
private struct OptionActionView: View {

  @ObservedObject var viewModel: OptionActionViewModel
  @Binding var showingDialog: Bool

  var body: some View {
    Button {
      showingDialog.toggle()
    } label: {
      VStack(spacing: 0) {
        viewModel.icon.image()
          .resizable()
          .scaledToFit()
          .foregroundStyle(viewModel.iconColor)
          .frame(width: 24, height: 24)

        Spacer().frame(height: 8)

        Text(viewModel.title)
          .foregroundStyle(.black)
          .font(.caption)
          .frame(maxWidth: .infinity)

        Spacer().frame(height: 8)

        Text(viewModel.description)
          .multilineTextAlignment(.center)
          .foregroundStyle(.blue)
          .font(.caption2)

        Spacer().frame(idealHeight: 16, maxHeight: 16)
      }
      .padding(.vertical)
      .padding(.horizontal, 4)
      .background(Color(uiColor: .systemFill))
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .confirmationDialog("Are you sure?", isPresented: $showingDialog) {
      Button(viewModel.actionTitle, role: .destructive) {
        viewModel.callAction()
      }
    } message: {
      Text(viewModel.actionMessage)
    }
  }

}

// MARK: Styles
private struct NoTapAnimationStyle: PrimitiveButtonStyle {

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .contentShape(Rectangle())
      .onTapGesture(perform: configuration.trigger)
  }

}

private struct MyToggleStyle: ToggleStyle {

  var onColor    = Color.green
  var offColor   = Color.gray
  var thumbColor = Color.white

  func makeBody(configuration: Self.Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      RoundedRectangle(cornerRadius: 16, style: .circular)
        .fill(configuration.isOn ? onColor : offColor)
        .frame(width: 50, height: 29)
        .overlay(
          Circle()
            .fill(thumbColor)
            .shadow(radius: 1, x: 0, y: 1)
            .padding(configuration.isOn ? 1.5 : 6)
            .offset(x: configuration.isOn ? 10 : -10))
        .animation(.easeInOut, value: configuration.isOn)
    }
    .buttonStyle(NoTapAnimationStyle())
  }

}

// MARK: Preview
#Preview {
  NavigationStack {
    AppOptionsView(store: AppOptionsStore())
      .padding(.horizontal, 24)
  }
}
