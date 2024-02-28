//
//  Combine+Extension.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 28/02/2024.
//

import Foundation
import Combine

extension CurrentValueSubject {

  @MainActor var valueOnMain: Output {
    get { value }
    set { send(newValue) }
  }

}
