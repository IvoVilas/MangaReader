//
//  Array+Extension.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 07/03/2024.
//

import Foundation

extension Array {

  func safeGet(_ i: Int) -> Element? {
    if self.indices.contains(i) {
      return self[i]
    }

    return nil
  }

}
