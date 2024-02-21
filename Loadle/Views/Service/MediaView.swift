//
//  MediaView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import Models
import SwiftUI

struct MediaView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var theme: Theme

    @Environment(Router.self) private var router: Router

    let service: MediaService

    var body: some View {
        ZStack {
            EmptyView()
        }
        .navigationTitle(service.title)
    }
}
