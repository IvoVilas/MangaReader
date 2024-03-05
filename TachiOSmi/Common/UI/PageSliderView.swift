//
//  PageSliderView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 05/03/2024.
//

import SwiftUI

struct PageSliderView: View {

  @Binding var value: Int
  let numberOfValues: Int
  let onChange: ((Int) -> Void)?

  @State private var sliderOffset: CGFloat = 0.0
  @State private var lastCoordinate: CGFloat = 0
  @State private var dotSize: CGFloat = 0
  @State private var width: CGFloat = 0

  var body: some View {
    GeometryReader { geo in
      let height = geo.size.height / 3
      let pointerSize = geo.size.height

      ZStack(alignment: .leading) {
        Rectangle()
          .fill(.white)
          .clipShape(RoundedRectangle(cornerRadius: height * 0.5))
          .frame(height: height)
          .onAppear { width = geo.size.width }

        Rectangle()
          .fill(.black)
          .frame(width: sliderOffset)
          .clipShape(RoundedRectangle(cornerRadius: height * 0.5))
          .frame(height: height)

        HStack(spacing: 0) {
          ForEach(Array(0..<numberOfValues), id:\.self) { index in
            Circle()
              .fill(.gray)
              .padding(.vertical, 2)
              .background(
                GeometryReader { geo in
                  Color.clear.onAppear {
                    dotSize = geo.size.width

                    if sliderOffset == 0 {
                      sliderOffset = dotSize / 2
                    }
                  }
                }
              )
              .contentShape(Rectangle())
              .onTapGesture {
                value = index
              }

            if index < numberOfValues - 1 { Spacer().frame(minWidth: 0) }
          }
        }
        .frame(width: width, height: height)

        Circle()
          .fill(.black)
          .offset(x: sliderOffset - (pointerSize * 0.5))
          .frame(height: pointerSize)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { s in
                let slide = s.translation.width

                if abs(slide) < 0.1 {
                  self.lastCoordinate = sliderOffset
                }

                let N = Double(numberOfValues)
                let nextCoordinate = between(
                  lastCoordinate + slide, 
                  min: 0,
                  max: width
                )

                value = Int((nextCoordinate / width * (N - 1)).rounded())

                let n = Double(value)
                let spacing = (width - (N * dotSize)) / (N - 1)
                sliderOffset = (n * (spacing + dotSize)) + (dotSize / 2)

                onChange?(value)
              }
          )
      }
    }
    .onChange(of: value) { oldValue, newValue in
      if newValue == oldValue { return }

      let N = Double(numberOfValues)

      let value = between(
        Double(newValue),
        min: 0,
        max: N - 1
      )

      let n = Double(value)
      let spacing = (width - (N * dotSize)) / (N - 1)
      sliderOffset = (n * (spacing + dotSize)) + (dotSize / 2)
    }
  }

  private func between(
    _ value: Double,
    min: Double,
    max: Double
  ) -> Double {
    if value > max { return max }

    if value < min { return min }

    return value
  }

}

private struct PagePreview: View {

  @State var value: Int = 0

  var body: some View {
    VStack {
      Text("\(value)")

      PageSliderView(
        value: $value,
        numberOfValues: 100,
        onChange: nil
      )
      .frame(height: 24)
      .padding(.horizontal, 24)

      Button { value += 1 } label: {
        Text("Change value")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.gray)
  }

}

#Preview {
  PagePreview()
}
