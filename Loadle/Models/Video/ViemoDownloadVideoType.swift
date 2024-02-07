//
//  ViemoDownloadVideoType.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

/// Pick `progressive` if you want best editor/player/social media compatibility. If Progressive download isn't available, dash is used instead.
enum ViemoDownloadVideoType: String, Encodable, CaseIterable {
    /// Direct file link to vimeo's cdn. max quality is 1080p.
    case progressive
    /// Video and audio are merged by cobalt into one file. max quality is 4k.
    case dash
}
