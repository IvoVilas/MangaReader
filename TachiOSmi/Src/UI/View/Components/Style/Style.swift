//
//  Style.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 26/02/2024.
//

import SwiftUI

struct StyleFonts: View {

  var body: some View {
    VStack(alignment: .leading) {
      Text("Large title").font(.largeTitle)

      Text("Title").font(.title)

      Text("Title 2").font(.title2)

      Text("Title 3").font(.title3)

      Text("Headline").font(.headline)

      Text("Subheadline").font(.subheadline)

      Text("Body").font(.body)

      Text("Callout").font(.callout)

      Text("Footnote").font(.footnote)

      Text("Caption").font(.caption)

      Text("Caption 2").font(.caption2)
    }
  }

}

struct StyleColors: View {

  @Environment(\.self) var environment

  private let gridRows = [
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  private let data: [(Color, String)] = [
    (.blue, "Blue"),
    (.init(uiColor: .blue), "UIBlue"),
    (.green, "Green"),
    (.init(uiColor: .green), "UIGreen"),
    (.indigo, "Indigo"),
    (.clear, UUID().uuidString),
    (.orange, "Oragne"),
    (.init(uiColor: .orange), "UIOrange"),
    (.pink, "Pink"),
    (.clear, UUID().uuidString),
    (.purple, "Purple"),
    (.init(uiColor: .purple), "UIPurple"),
    (.red, "Red"),
    (.init(uiColor: .red), "UIRed"),
    (.teal, "Teal"),
    (.clear, UUID().uuidString),
    (.yellow, "Yellow"),
    (.init(uiColor: .yellow), "UIYellow"),
    (.gray, "Gray"),
    (.init(uiColor: .gray), "UIGray"),
    (.init(uiColor: .darkGray), "DarkGray"),
    (.init(uiColor: .lightGray), "LightGray"),
    (.init(uiColor: .systemGray2), "SystemGray2"),
    (.init(uiColor: .systemGray3), "SystemGray3"),
    (.init(uiColor: .systemGray4), "SystemGray4"),
    (.init(uiColor: .systemGray5), "SystemGray5"),
    (.init(uiColor: .systemGray6), "SystemGray6"),
    (.init(uiColor: .systemBackground), "Background"),
    (.init(uiColor: .secondarySystemBackground), "SecondaryBackground"),
    (.init(uiColor: .tertiarySystemBackground), "TertiaryBackground"),
    (.init(uiColor: .systemGroupedBackground), "Grouped"),
    (.init(uiColor: .secondarySystemGroupedBackground), "SecondaryGrouped"),
    (.init(uiColor: .tertiarySystemGroupedBackground), "TertiaryGrouped"),
    (.init(uiColor: .systemFill), "Fill"),
    (.init(uiColor: .secondarySystemFill), "SecondaryFill"),
    (.init(uiColor: .tertiarySystemFill), "TertiaryFill"),
    (.init(uiColor: .quaternarySystemFill), "TertiaryFill"),
    (.init(uiColor: .lightText), "LightText"),
    (.init(uiColor: .darkText), "DarkText"),
    (.init(uiColor: .label), "Label"),
    (.init(uiColor: .secondaryLabel), "SecondaryLabel"),
    (.init(uiColor: .tertiaryLabel), "TertiaryLabel"),
    (.init(uiColor: .quaternaryLabel), "QuaternaryLabel"),
    (.init(uiColor: .link), "Link"),
    (.init(uiColor: .placeholderText), "PlaceholderText"),
    (.init(uiColor: .separator), "Separator"),
    (.init(uiColor: .opaqueSeparator), "OpaqueSeparator")
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: gridRows, spacing: 0)  {
        ForEach(data, id: \.self.1) { item in
          Text(item.1)
            .font(.callout)
            .frame(height: 100, alignment: .center)
            .frame(maxWidth: .infinity)
            .background(item.0)
            .foregroundColor(item.0 == .clear ? .clear : .black)
            .font(.title)
        }
      }
    }
  }

}

#Preview {
  StyleFonts()
}

#Preview {
  StyleColors()
}
