//
//  PageSliderView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 05/03/2024.
//

import SwiftUI

struct PageSliderView: View {

  @Binding var value: String?
  let values: [String]

  @State private var sliderValue: Int
  @State private var sliderOffset: CGFloat = 0.0
  @State private var lastCoordinate: CGFloat = 0
  @State private var dotSize: CGFloat = 0
  @State private var width: CGFloat = 0

  init(
    value: Binding<String?>,
    values: [String]
  ) {
    self._value = value
    self.values = values

    if let v = value.wrappedValue {
      sliderValue = values.firstIndex(of: v) ?? 0
    } else {
      sliderValue = 0
    }
  }

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
          ForEach(Array(0..<values.count), id:\.self) { index in
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
                if index != sliderValue {
                  sliderValue = index

                  if let v = values.safeGet(index) {
                    value = v
                  }
                }
              }

            if index < values.count - 1 {
              Spacer().frame(minWidth: 0)
            }
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

                let N = Double(values.count)
                let nextCoordinate = between(
                  lastCoordinate + slide, 
                  min: 0,
                  max: width
                )

                let oldValue = sliderValue
                let newValue = Int((nextCoordinate / width * (N - 1)).rounded())

                if oldValue != newValue {
                  sliderValue = newValue

                  let n = Double(sliderValue)
                  let spacing = (width - (N * dotSize)) / (N - 1)
                  sliderOffset = (n * (spacing + dotSize)) + (dotSize / 2)

                  if let v = values.safeGet(newValue) {
                    value = v
                  }
                }
              }
          )
      }
    }
    .onChange(of: value) { oldValue, newValue in
      guard 
        newValue != oldValue,
        let newValue,
        let sliderValue = values.firstIndex(of: newValue) 
      else {
        return
      }

      let N = Double(values.count)

      let value = between(
        Double(sliderValue),
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

  @State var value: String? = nil

  let values = ["1", "2", "3", "4", "5"]

  var body: some View {
    VStack {
      Text(value ?? "nil")

      PageSliderView(
        value: $value,
        values: values
      )
      .frame(height: 24)
      .padding(.horizontal, 24)

      Button {
        value = values[Int.random(in: 0..<values.count)]
      } label: {
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
