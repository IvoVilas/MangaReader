//
//  Style.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 26/02/2024.
//

import SwiftUI

struct Style: View {
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

#Preview {
  Style()
}
