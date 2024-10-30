//
//  ToastView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import SwiftUI

// MARK: ToastStyle
enum ToastStyle {
  case error
  case warning
  case success
  case info

  var themeColor: Color {
    switch self {
    case .error: return Color.red
    case .warning: return Color.orange
    case .info: return Color.blue
    case .success: return Color.green
    }
  }

  var iconFileName: String {
    switch self {
    case .info: return "info.circle.fill"
    case .warning: return "exclamationmark.triangle.fill"
    case .success: return "checkmark.circle.fill"
    case .error: return "xmark.circle.fill"
    }
  }
}

// MARK: ToastModel
struct Toast: Equatable {

  let style: ToastStyle
  let message: String
  let duration: Double = 3
  let width: Double = .infinity

  init(style: ToastStyle, message: String) {
    self.style = style
    self.message = message
  }

  init(using info: ToastInfo) {
    self.style = info.style
    self.message = info.message
  }

}

// MARK: ToastView
struct ToastView: View {

  var style: ToastStyle
  var message: String
  var width = CGFloat.infinity
  var onCancelTapped: (() -> Void)

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: style.iconFileName)
        .foregroundColor(style.themeColor)

      Text(message)
        .font(Font.caption)
        .foregroundColor(.black)

      Spacer(minLength: 10)

      Button {
        onCancelTapped()
      } label: {
        Image(systemName: "xmark")
          .foregroundColor(style.themeColor)
      }
    }
    .padding()
    .frame(minWidth: 0, maxWidth: width)
    .background(.white)
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(style.themeColor, lineWidth: 2)
        .opacity(0.6)
    )
    .padding(.horizontal, 16)
  }
}

// MARK: ToastModifier
struct ToastModifier: ViewModifier {

  @Binding var toast: Toast?
  @State private var workItem: DispatchWorkItem?

  func body(content: Content) -> some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .overlay(
        ZStack {
          mainToastView()
            .offset(y: 32)
        }.animation(.spring(), value: toast)
      )
      .onChange(of: toast) { _, value in
        showToast()
      }
  }

  @ViewBuilder func mainToastView() -> some View {
    if let toast = toast {
      VStack {
        Spacer()

        ToastView(
          style: toast.style,
          message: toast.message,
          width: toast.width
        ) {
          dismissToast()
        }
      }
      .padding(.bottom, 48)
    }
  }

  private func showToast() {
    guard let toast = toast else { return }

    UIImpactFeedbackGenerator(style: .light)
      .impactOccurred()

    if toast.duration > 0 {
      workItem?.cancel()

      let task = DispatchWorkItem {
        dismissToast()
      }

      workItem = task
      DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
    }
  }

  private func dismissToast() {
    withAnimation {
      toast = nil
    }

    workItem?.cancel()
    workItem = nil
  }
}

extension View {

  func toastView(toast: Binding<Toast?>) -> some View {
    self.modifier(ToastModifier(toast: toast))
  }

}

#Preview {
  ScrollView {
    VStack {
      ToastView(
        style: .error,
        message: "This is an error"
      ) {
        print("Cancel tapped")
      }

      ToastView(
        style: .warning,
        message: "This is a warning"
      ) {
        print("Cancel tapped")
      }

      ToastView(
        style: .info,
        message: "This is info"
      ) {
        print("Cancel tapped")
      }

      ToastView(
        style: .success,
        message: "This is success"
      ) {
        print("Cancel tapped")
      }
    }
  }
}
