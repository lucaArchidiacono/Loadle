//
//  OnboardingView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 15.03.2024.
//

import Environments
import Foundation
import Generator
import SwiftUI

@MainActor
struct OnboardingView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @Environment(Router.self) private var router: Router

    var body: some View {
        VStack {
            title
            list
            button
        }
    }

    var title: some View {
        Text(L10n.onboardingTitle)
            .font(.largeTitle)
            .fontWeight(.bold)
            .padding(.top, 50)
            .padding(.horizontal)
    }

    var list: some View {
        List {
            Group {
                OnboardingItem(imageName: "square.and.arrow.down.fill",
                               title: L10n.onboardingDownloadTitle,
                               description: L10n.onboardingDownloadDescription)
                OnboardingItem(imageName: "lock.fill",
                               title: L10n.onboardingPrivacyPolicyTitle,
                               description: L10n.onboardingPrivacyPolicyDescription)
                OnboardingItem(imageName: "popcorn.fill",
                               title: L10n.onboardingSupportedServicesTitle,
                               description: L10n.onboardingSupportedServicesDescription)
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.clear)
    }

    var button: some View {
        Button {
            preferences.showOnboarding = false
            router.dismiss()
        } label: {
            Text(L10n.continue)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
        }
        .padding()
        .buttonStyle(.borderedProminent)
    }
}

private struct OnboardingItem: View {
    var imageName: String
    var title: String
    var description: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.tint)
                .frame(width: 50, height: 50)
                .padding()

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    @State var isPresented: Bool = true
    return NavigationStack {
        Text("")
            .sheet(isPresented: $isPresented, content: {
                OnboardingView()
                    .environmentObject(UserPreferences.shared)
                    .environment(Router())
            })
    }
}
