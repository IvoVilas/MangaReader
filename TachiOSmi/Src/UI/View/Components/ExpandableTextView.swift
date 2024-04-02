//
//  ExpandableTextView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 03/04/2024.
//

import SwiftUI

struct ExpandableTextView: View {

  @State var text: String
  @State private var isExpanded: Bool = false
  @State private var shouldShowMoreButton: Bool = false

  let font: Font
  let textColor: Color

  private let lineLimit: Int = 3

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ZStack(alignment: .bottom) {
        Text(text)
          .font(font)
          .lineLimit(isExpanded ? nil : lineLimit)
          .foregroundStyle(textColor)
          .animation(.spring, value: isExpanded)

          LinearGradient(
            gradient: Gradient(colors: [.clear, .white]),
            startPoint: .center,
            endPoint: .bottom
          )
          .frame(height: 60)
          .opacity(!isExpanded && shouldShowMoreButton ? 1 : 0)
      }
      .background(
        GeometryReader { geometryProxy in
          Color.clear.onAppear {
            let textSize = textSizeWithoutLimit(geometry: geometryProxy)
            let limitedTextSize = textSizeWithLimit(geometry: geometryProxy, lineLimit: lineLimit)
            
            shouldShowMoreButton = textSize.height > limitedTextSize.height
          }
        }
      )

      HStack(spacing: 0) {
        Spacer()

        Button {
          withAnimation {
            isExpanded.toggle()
          }
        } label: {
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .foregroundColor(.black)
        }
        .contentTransition(.symbolEffect(.automatic))

        Spacer()
      }
      .opacity(shouldShowMoreButton ? 1 : 0)
    }
  }

  private func textSizeWithoutLimit(geometry: GeometryProxy) -> CGSize {
    let textSize = text.boundingRect(
      with: CGSize(width: geometry.size.width, height: .infinity),
      options: .usesLineFragmentOrigin,
      attributes: [.font: UIFont.preferredFont(from: font)],
      context: nil
    ).size

    return textSize
  }

  private func textSizeWithLimit(geometry: GeometryProxy, lineLimit: Int) -> CGSize {
    let textSize = text.boundingRect(
      with: CGSize(
        width: geometry.size.width,
        height: CGFloat(lineLimit) * UIFont.preferredFont(from: font).lineHeight
      ),
      options: .usesLineFragmentOrigin,
      attributes: [.font: UIFont.preferredFont(from: font)],
      context: nil
    ).size

    return textSize
  }
}

#Preview {
  ExpandableTextView(
    text: "Yuuji is a genius at track and field. But he has zero interest running around in circles, he's happy as a clam in the Occult Research Club. Although he's only in the club for kicks, things get serious when a real spirit shows up at school! Life's about to get really strange in Sugisawa Town #3 High School!",
    font: .footnote,
    textColor: .black
  )
}

extension UIFont {
  class func preferredFont(from font: Font) -> UIFont {
    let style: UIFont.TextStyle
    switch font {
    case .largeTitle:
      style = .largeTitle

    case .title:
      style = .title1

    case .title2:
      style = .title2

    case .title3:
      style = .title3

    case .headline:
      style = .headline

    case .subheadline:
      style = .subheadline

    case .callout:
      style = .callout

    case .caption:
      style = .caption1

    case .caption2:
      style = .caption2

    case .footnote:
      style = .footnote

    case .body:
      fallthrough

    default:
      style = .body
    }
    return  UIFont.preferredFont(forTextStyle: style)
  }
}
