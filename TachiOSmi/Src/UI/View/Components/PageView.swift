//
//  PageView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 27/03/2024.
//

import Foundation
import SwiftUI

struct PageView: View, Equatable {

  let page: PageModel
  let allowsZoom: Bool
  let reloadAction: ((PageModel) async -> Void)?

  static func == (lhs: PageView, rhs: PageView) -> Bool {
    if lhs.page.id != rhs.page.id { return false }

    switch (lhs.page, rhs.page) {
    case (.loading, .loading), (.remote, .remote), (.notFound, .notFound):
      return true

    default:
      return false
    }
  }

  var body: some View {
    switch page {
    case .remote(_, _, let data):
      ZoomableImageView(
        image: UIImage(data: data) ?? .imageNotFound,
        allowsZoom: allowsZoom
      )
      .frame(width: UIScreen.main.bounds.width)

    case .loading:
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
        .frame(
          width: UIScreen.main.bounds.width,
          height: UIScreen.main.bounds.height
        )

    case .notFound:
      ZStack(alignment: .bottom) {
        Image(uiImage: .imageNotFound)
          .resizable()
          .aspectRatio(contentMode: .fit)

        Button {
          Task(priority: .userInitiated) { await reloadAction?(page) }
        } label: {
          HStack(alignment: .center, spacing: 8) {
            Text("Retry")
              .font(.body)
              .foregroundStyle(.white)

            Image(systemName: "arrow.triangle.2.circlepath.icloud")
              .tint(.white)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(.black)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .padding(.horizontal, 24)
          .padding(.bottom, 24)
        }
      }
      .frame(width: UIScreen.main.bounds.width)
    }
  }

}

#Preview {
  ScrollView(.horizontal) {
    HStack(spacing: 0) {
      PageView(
        page: .notFound("1", 1),
        allowsZoom: true
      ) { _ in }

      PageView(
        page: .loading("2", 2),
        allowsZoom: true
      ) { _ in }
    }
  }
  .scrollTargetBehavior(.paging)
  .background(.black)
}
