//
//  ChapterDownloadInfo.swift
//  TachiOSmi
//
//  Created by Ivo Vilas on 27/02/2024.
//

import Foundation

protocol ChapterDownloadInfo: Identifiable {

  var numberOfPages: Int { get }
  var pages: [String] { get }

}
