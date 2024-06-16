//
//  NotificationManager.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 05/06/2024.
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, ObservableObject {

  @Published var navigator: (any Navigator)?

  private let notificationCenter: UNUserNotificationCenter

  init(mock: Bool = false) {
    notificationCenter = .current()

    super.init()

    if !mock {
      notificationCenter.delegate = self
    }
  }

  func requestNotificationPermission() async {
    guard await canRequestAuthorization() else {
      return
    }

    do {
      let options: UNAuthorizationOptions = [.alert, .badge, .sound]

      if try await notificationCenter.requestAuthorization(options: options) {
        print("NotificationManager -> User granted authorization to send notifications")
      } else {
        print("NotificationManager -> User did not grant authorization to send notifications")
      }
    } catch {
      print("NotificationManager -> Error during authorization request: \(error.localizedDescription)")
    }
  }

  func scheduleChapterNotification(
    for manga: MangaModel,
    description: ChapterUpdate
  ) {
    let content = UNMutableNotificationContent()

    content.title = manga.title
    content.sound = .default
    content.userInfo = [
      "manga": manga.id,
      "source": manga.source.id
    ]

    switch description {
    case .single(let chapter):
      content.body = chapter
    case .multiple(let count):
      content.body = "\(count) new chapters"
    }

    if
      let coverUrl = getCoverUrl(mangaId: manga.id, data: manga.cover),
      let attachment = try? UNNotificationAttachment(identifier: "imageAttachment", url: coverUrl)
    {
      content.attachments = [attachment]
    }

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    notificationCenter.add(request) { error in
      if let error {
        print("NotificationManager -> Error scheduling new \(manga.title) chapter notification: \(error.localizedDescription)")
      } else {
        print("NotificationManager -> New chapter \(manga.title) notification scheduled")
      }
    }
  }

  func scheduleNoNewChaptersNotification() {
    let content = UNMutableNotificationContent()

    content.title = "Finished refresing your library"
    content.sound = .default
    content.body = "No new chapters were found"

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    notificationCenter.add(request) { error in
      if let error {
        print("NotificationManager -> Error scheduling notification: \(error.localizedDescription)")
      } else {
        print("NotificationManager -> New notification scheduled")
      }
    }
  }

}

extension NotificationManager: UNUserNotificationCenterDelegate {

  @MainActor
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    let userInfo = response.notification.request.content.userInfo
    
    if let manga = userInfo["manga"] as? String, let source = userInfo["source"] as? String {
      navigator = MangaDetailsNavigator(
        id: manga,
        sourceId: source
      )
    }
  }

}

extension NotificationManager {

  private func canRequestAuthorization() async -> Bool {
    let settings = await notificationCenter.notificationSettings()

    switch settings.authorizationStatus {
    case .notDetermined:
      return true

    default:
      return false
    }
  }

  private func getCoverUrl(
    mangaId: String,
    data: Data?
  ) -> URL? {
    guard let data else { return nil }

    do {
      let fileManager = FileManager.default
      let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      let coverUrl = cachesDirectory.appendingPathComponent("\(mangaId).jpg")

      if !fileManager.fileExists(atPath: coverUrl.path()) {
        try data.write(to: coverUrl)
      }

      return coverUrl
    } catch {
      print("NotificationManager -> Error saving cover locally: \(error.localizedDescription)")

      return nil
    }
  }

}

extension NotificationManager {

  enum ChapterUpdate {
    case single(String)
    case multiple(Int)
  }

}
