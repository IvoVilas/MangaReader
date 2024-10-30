//
//  LocalFileManager.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 24/10/2024.
//

import Foundation
import UIKit

final class LocalFileManager {

  private let fileManager: FileManager

  init() {
    fileManager = .default
  }

  func saveImage(
    _ data: Data,
    withName name: String
  ) -> Bool {
    guard let url = getDocumentsDirectory()?.appendingPathComponent("\(name).jpg") else {
      print("LocalFileManager -> Error: Couldn't create file URL")
      return false
    }

    do {
      try data.write(to: url)

      return true
    } catch {
      print("LocalFileManager -> Error: Couldn't save image - \(error)")

      return false
    }
  }

  func loadImage(
    withName name: String
  ) -> Data? {
    guard let url = getDocumentsDirectory()?.appendingPathComponent("\(name).jpg") else {
      print("LocalFileManager -> Error: Couldn't create file URL")

      return nil
    }

    if fileManager.fileExists(atPath: url.path) {
      return try? Data(
        contentsOf: url
      )
    } else {
      print("LocalFileManager -> Error: Image not found at path \(url.path)")

      return nil
    }
  }

  func deleteImage(
    withName name: String
  ) -> Bool {
    do {
      guard let url = getDocumentsDirectory()?.appendingPathComponent("\(name).jpg") else {
        print("LocalFileManager -> Error: Couldn't create file URL")

        return false
      }

      try fileManager.removeItem(atPath: url.path)

      return true
    } catch {
      print("LocalFileManager -> Error: Couldn't delete image - \(error)")

      return false
    }
  }

  func deleteAllImages() -> Bool {
    guard let documentsURL = getDocumentsDirectory() else {
      print("LocalFileManager -> Couldn't get documents directory URL")

      return false
    }

    do {
      let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

      for fileURL in fileURLs {
        if fileURL.pathExtension == "jpg" || fileURL.pathExtension == "png" || fileURL.pathExtension == "jpeg" {
          try fileManager.removeItem(at: fileURL)
        }
      }
      return true
    } catch {
      print("LocalFileManager -> Error: Couldn't delete all images - \(error.localizedDescription)")

      return false
    }
  }

}

extension LocalFileManager {

  private func getDocumentsDirectory() -> URL? {
    return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
  }

}
