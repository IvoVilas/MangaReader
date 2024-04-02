//
//  ZoomImageView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 02/04/2024.
//

import SwiftUI

struct ZoomImagesView: View {
  let images: [String]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 0) {
        ForEach(images, id: \.self) { image in
          ZoomImageView(
            image: UIImage(named: image)!
          )
          .frame(width: UIScreen.main.bounds.width)
        }
      }
    }
    .scrollTargetBehavior(.paging)
    .ignoresSafeArea()
  }

}

struct ZoomImageView: View {

  private static var maxScale: CGFloat = 4
  private static var defaultScale: CGFloat = 2

  var image: UIImage

  @State private var scale: CGFloat = 1.0
  @State private var offset: CGSize = .zero
  @State private var imageSize: CGSize = .zero

  var body: some View {
    Image(uiImage: image)
      .resizable()
      .scaledToFit()
      .scaleEffect(scale)
      .offset(offset)
      .background(.red)
      .background(
        GeometryReader { geo in
          Color.clear.onAppear {
            imageSize = geo.size
          }
        }
      )
      .gesture(buildGesture(hasPan: scale > 1))
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
          ZoomImageView.maxScale
        )

        if scale != newScale {
          scale = newScale

          offset = limitOffset(
            offset,
            scale: newScale,
            size: imageSize
          )
        }
      }
      .simultaneously(
        with: hasPan ? Optional(DragGesture(
          minimumDistance: 0,
          coordinateSpace: .global
        ).onChanged { gesture in
          guard scale > 1 else { return }

          let newOffset = CGSize(
            width: offset.width + gesture.translation.width / 2,
            height: offset.height + gesture.translation.height / 2
          )

          offset = limitOffset(
            newOffset,
            scale: scale,
            size: imageSize
          )
        }
        ) : nil
      )
      .simultaneously(
        with: TapGesture(count: 2).onEnded { position in
          if scale == 1 {
            scale = ZoomImageView.defaultScale
          } else {
            scale = 1
            offset = .zero
          }
        }
      )
  }

}

#Preview {
  ZoomImageView(
    image: .jujutsuCover
  )
}

#Preview {
  ZoomImagesView(images: ["jujutsu_cover", "cover_not_found"])
}
