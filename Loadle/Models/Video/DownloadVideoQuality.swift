//
//  DownloadVideoQuality.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

enum DownloadVideoQuality: String, Encodable, CaseIterable {
    case _360 = "360"
    case _480 = "480"
    case _720 = "720"
    case _1080 = "1080"
    case _1440 = "1440"
    case _2160 = "2160"
    case max
}
