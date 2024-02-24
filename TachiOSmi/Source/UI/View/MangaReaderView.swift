//
//  MangaReaderView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 24/02/2024.
//

import SwiftUI
import Combine

struct MangaReaderView: View {

  @ObservedObject var viewModel: MangaReaderViewModel

  var body: some View {
    GeometryReader { geo in
      ScrollView(.horizontal) {
        HStack(spacing: 0) {
          ForEach(Array(viewModel.pages.enumerated()), id:\.offset) { _, viewModel in
            ImageView(viewModel: viewModel)
              .frame(width: geo.size.width)
              .frame(maxWidth: geo.size.width, maxHeight: .infinity, alignment: .center)
          }
        }
      }
      .scrollTargetBehavior(.paging)
      .background(.black)
      .onAppear { viewModel.viewDidAppear() }
    }
  }

}

struct ImageView: View {

  @ObservedObject var viewModel: ImageViewModel

  var body: some View {
    ZStack {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
        .opacity(viewModel.isLoading ? 1 : 0)

      make(viewModel.page)
    }
  }

  @ViewBuilder
  private func make(_ image: UIImage?) -> some View {
    if let image {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }

    EmptyView()
  }

}

#Preview {
  MangaReaderView(
    viewModel: MangaReaderViewModel(
      baseUrl: "https://uploads.mangadex.org",
      chapterHash: "fc7ad9507c7e93a0ed2c546a3901cdfc",
      data: [
        "1-5244c1e63e2e61ece0c523e94acd5507672055d53a274f59d7e6a87b79e322c6.png",
        "2-0a4ef67a93255bd0a11674565b5d262834b30a0dcf886e34c63e1ca151ee9ef5.png",
        "3-a73a213379ce88c6c4bc12ad7cbbfff627b82cab364b932ce7036b973f7485bd.png",
        "4-7b20d925cbd7956b229d7a47584ee630783e80e150ffc609f150d608dd29cf39.png",
        "5-0c8ef16ecf2cbe18fdd3c0d749a842c8666180f3e0b8d5e790e99e81162810ac.png",
        "6-b8ab28f70ccc5cab05708b5ec95d77d29dc7581ee5ed312ff2dc85d266ed0eec.png",
        "7-07dc6a16d29e40a23e3553f584246191dca17a97b00e8779549c40021a5438e0.png",
        "8-b64ee578eb8aa640e9830fb0a81f682f719badaf60dc8ae4126423e565769490.png",
        "9-b0a4f5d41267c0dc73ad988e6a736ba27ea1b94cecc7ce764aa38ab2cac84b0c.png",
        "10-098f0fe49b327ebd4a1e9c8b1617bed895817c2bb5fe04fbd77e34b880afef19.png",
        "11-e74cceacc6815cef52a90f7a4eb2b76ee778012135adf1aaaa1492dca5190237.png",
        "12-8acc3ba714687cc309887c72f3014289d81daf047fb9ecc9d57cbfcf43417a53.png",
        "13-76a7d843b3a26c80493eaafae0a8f75e882ea85983cb40463aa141203f60ac79.png",
        "14-020bb75e0d55932dd4fe66b0cbc5f66ff7b18d63a2d9e0f36d8f2423268c76e9.png",
        "15-61db2764948782ab5be90ac13ffbc2d4f68a6d29d2e0c0feba59d07693464907.png",
        "16-97f3c655a706d6958d1339f47f394f778a9928a23e4d03250e257507db7bb70f.png",
        "17-ecfeda1d382fefc65a639f72d5a0c66a49d11a11e528d0115a02bd7efcf757a1.png",
        "18-80a25076627ae1342a59f539639cc53d71c8fff5df79e0a042bf8e4edc887d17.png"
      ],
      restRequester: RestRequester()
    )
  )
}
