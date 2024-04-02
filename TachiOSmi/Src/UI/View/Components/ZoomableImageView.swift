//
//  ZoomableImageView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 02/04/2024.
//

import SwiftUI

struct ZoomableImageView: View {

  private static var maxScale: CGFloat = 4
  private static var defaultScale: CGFloat = 2

  var image: UIImage
  let allowsZoom: Bool

  @State private var scale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var dragAmount: CGSize = .zero
  @State private var imageSize: CGSize = .zero

  var body: some View {
    Image(uiImage: image)
      .resizable()
      .scaledToFit()
      .scaleEffect(scale)
      .offset(limitOffset(
        CGSize(
          width: offset.width + dragAmount.width,
          height: offset.height + dragAmount.height
        ),
        scale: scale,
        size: imageSize)
      )
      .background(
        GeometryReader { geo in
          Color.clear.onAppear {
            imageSize = geo.size
          }
        }
      )
      .if(allowsZoom) {
        $0.gesture(buildGesture(hasPan: scale > 1))
      }
      .animation(.easeIn, value: scale)
      //.animation(.linear, value: offset)
      .frame(maxHeight: .infinity)
  }

  private func limitOffset(
    _ offset: CGSize,
    scale: CGFloat,
    size: CGSize
  ) -> CGSize {
    let maxWidth = max(0, size.width * (scale - 1) / 2)
    let maxHeight = max(0, size.height * (scale - 1) / 2)

    return CGSize(
      width: min(maxWidth, max(offset.width, -maxWidth)),
      height: min(maxHeight, max(offset.height, -maxHeight))
    )
  }

  private func buildGesture(
    hasPan: Bool
  ) -> some Gesture {
    MagnificationGesture()
      .onChanged { value in
        let newScale = min(
          max(1, value.magnitude),
          ZoomableImageView.maxScale
        )

        if scale != newScale {
          scale = newScale
        }
      }
      .simultaneously(
        with: hasPan ? Optional(DragGesture(
          minimumDistance: 0,
          coordinateSpace: .global
        ).onChanged { gesture in
          guard scale > 1 else { return }

          self.dragAmount = gesture.translation
        }.onEnded { gesture in
          offset.width += gesture.translation.width
          offset.height += gesture.translation.height
          dragAmount = .zero
        }
        ) : nil
      )
      .simultaneously(
        with: TapGesture(count: 2).onEnded { position in
          if scale == 1 {
            scale = ZoomableImageView.defaultScale
          } else {
            scale = 1
            offset = .zero
          }
        }
      )
  }

}

#Preview {
  ZoomableImageView(
    image: .jujutsuCover,
    allowsZoom: true
  )
}

#Preview {
  ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 0) {
      ForEach(["jujutsu_cover", "cover_not_found"], id: \.self) { image in
        ZoomableImageView(
          image: UIImage(named: image)!,
          allowsZoom: true
        )
        .frame(width: UIScreen.main.bounds.width)
      }
    }
  }
  .scrollTargetBehavior(.paging)
  .ignoresSafeArea()
}
