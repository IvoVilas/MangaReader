//
//  ContentView.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 01/03/2024.
//

import SwiftUI

struct ContentView: View {

  enum Tabs: String {
    case library
    case updates
    case search
    case options
  }

  @Environment(\.appOptionsStore) private var optionsStore
  @Environment(\.colorScheme) private var scheme

  @StateObject private var router = Router()
  @ObservedObject var notificationManager: NotificationManager

  @State private var colorScheme: ColorScheme = .light
  @State private var selectedTab: Tabs = .library

  var body: some View {
    NavigationStack(path: $router.navPath) {
      TabView(selection: $selectedTab) {
        MangaLibraryView()
          .padding(top: 24, leading: 24, trailing: 24)
          .tabItem {
            Label(
              title: { Text("Library") },
              icon: { Image(systemName: "book.closed.fill") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
          .tag(Tabs.library)

        MangaUpdatesView()
          .padding(top: 24, leading: 24, trailing: 24)
          .tabItem {
            Label(
              title: { Text("Updates") },
              icon: { Image(systemName: "clock.arrow.2.circlepath") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
          .tag(Tabs.updates)

        MangaSourcesView()
          .padding(top: 24, leading: 24, trailing: 24)
          .tabItem {
            Label(
              title: { Text("Search") },
              icon: { Image(systemName: "safari") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
          .tag(Tabs.search)

        AppOptionsView()
          .padding(top: 24, leading: 24, trailing: 24)
          .tabItem {
            Label(
              title: { Text("More") },
              icon: { Image(systemName: "ellipsis") }
            )
          }
          .toolbarBackground(.visible, for: .tabBar)
          .tag(Tabs.options)
      }
      .navigationTitle(selectedTab.rawValue.capitalized)
      .toolbar(.hidden, for: .navigationBar)
      .registerNavigator(MangaDetailsNavigator.self)
      .registerNavigator(MangaReaderNavigator.self)
      .registerNavigator(MangaSearchNavigator.self)
      .registerNavigator(MangaGlobalSearchNavigator.self)
    }
    .environment(\.router, router)
    .environment(\.colorScheme, colorScheme)
    .onReceive(optionsStore.appThemePublisher) {
      colorScheme = $0.toColorScheme(system: scheme)
    }
    .onReceive(notificationManager.$navigator) { navigator in
      if let navigator {
        router.navigateToRootAndThen(to: navigator)
      }
    }
  }

}

extension UINavigationController: UIGestureRecognizerDelegate {

  override open func viewDidLoad() {
    super.viewDidLoad()

    interactivePopGestureRecognizer?.delegate = self
  }

  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return viewControllers.count > 1
  }

}

#Preview {
  ContentView(notificationManager: NotificationManager())
}
