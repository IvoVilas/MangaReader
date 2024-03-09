//
//  Data+Extensions.swift
//  TachiOSmi
//
//  Created by Ivo Vilas Boas  on 09/03/2024.
//

import Foundation
import UIKit

extension Data? {

  func toUIImage() -> UIImage? {
    guard let self else { return nil }

    return UIImage(data: self)
  }

}
