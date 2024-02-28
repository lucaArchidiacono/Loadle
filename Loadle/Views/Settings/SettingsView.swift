//
//  SettingsView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Environments
import Foundation
import Generator
import Models
import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private enum Segment: String, CaseIterable {
        case video
        case audio
        case other

        var rawValue: String {
            switch self {
            case .video: return L10n.video
            case .audio: return L10n.audio
            case .other: return L10n.other
            }
        }
    }

    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var theme: Theme
    @Environment(Router.self) private var router: Router

    @State private var viewModel: SettingsViewModel = .init()
    @State private var selected: Segment = .video

    var body: some View {
        List {
            Section {
                Picker("", selection: $selected) {
                    ForEach(Segment.allCases, id: \.self) { segment in
                        Text(segment.rawValue)
							.tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
				.id("segment")
            }
			.listRowBackground(theme.primaryBackgroundColor)

            switch selected {
            case .video:
                videoSegment
            case .audio:
                audioSegment
            case .other:
                otherSegment
            }
        }
        .toolbar {
            DoneToolbar(placement: .topBarTrailing) {
                dismiss()
            }
        }
        .applyTheme(theme)
        .background(theme.secondaryBackgroundColor)
        .scrollContentBackground(.hidden)
        .navigationTitle(L10n.settings)
    }

    @ViewBuilder
    var videoSegment: some View {
        Section {
            Picker(L10n.settingsVideoQualityTitle, selection: preferences.$videoDownloadQuality) {
                ForEach(DownloadVideoQuality.allCases, id: \.self) { quality in
                    Text(quality == .max ? L10n.max : quality.rawValue)
                }
            }
        } footer: {
            Text(L10n.settingsVideoQualityDescription)
        }
		.listRowBackground(theme.primaryBackgroundColor)
        Section {
            Toggle(isOn: preferences.$videoTiktokWatermarkDisabled, label: {
                Text(L10n.settingsVideoTiktokTitleDisableWatermark)
            })
        } header: {
            Text(L10n.tiktok)
        }
			.listRowBackground(theme.primaryBackgroundColor)
        Section {
            Toggle(isOn: preferences.$videoTwitterConvertGifsToGif, label: {
                Text(L10n.settingsVideoTwitterTitleConvertGifsToGif)
            })
        } header: {
            Text(L10n.twitter)
        } footer: {
            Text(L10n.settingsVideoTwitterDescriptionConvertGifsToGif)
        }
					.listRowBackground(theme.primaryBackgroundColor)

        Section {
            Picker(L10n.settingsVideoYoutubeTitleCodec, selection: preferences.$videoYoutubeCodec) {
                ForEach(YoutubeVideoCodec.allCases, id: \.self) { codec in
                    Text(codec.rawValue.uppercased())
                }
            }
        } header: {
            Text(L10n.youtube)
        } footer: {
            Text(L10n.settingsVideoYoutubeDescriptionCodec)
        }
					.listRowBackground(theme.primaryBackgroundColor)

		Section {
            Picker(L10n.settingsVideoVimeoTitleDownloadType, selection: preferences.$videoVimeoDownloadType) {
                ForEach(ViemoDownloadVideoType.allCases, id: \.self) { type in
                    switch type {
                    case .progressive:
                        Text(L10n.progressive)
                    case .dash:
                        Text(L10n.dash)
                    }
                }
            }
        } header: {
            Text(L10n.vimeo)
        } footer: {
            Text(L10n.settingsVideoVimeoDescriptionDownloadType)
        }
		.listRowBackground(theme.primaryBackgroundColor)
    }

    @ViewBuilder
    var audioSegment: some View {
        Section {
            Picker(L10n.settingsAudioFormatHeader, selection: preferences.$audioFormat) {
                ForEach(AudioFormat.allCases, id: \.self) { format in
                    Text(format == .best ? L10n.best : format.rawValue.uppercased())
                }
            }
        } footer: {
            Text(L10n.settingsAudioFormatDescription)
        }
		.listRowBackground(theme.primaryBackgroundColor)
        Section {
            Toggle(isOn: preferences.$audioMute, label: {
                Text(L10n.settingsAudioMuteTitle)
            })
        } footer: {
            Text(L10n.settingsAudioMuteDescription)
        }
		.listRowBackground(theme.primaryBackgroundColor)
        Section {
            Picker(L10n.settingsAudioYoutubeTitleAudioTrack, selection: preferences.$audioYoutubeTrack) {
                ForEach(YoutubeAudioTrack.allCases, id: \.self) { track in
                    switch track {
                    case .auto:
                        Text(L10n.auto)
                    case .original:
                        Text(L10n.original)
                    }
                }
            }
        } header: {
            Text(L10n.youtube)
        } footer: {
            Text(L10n.settingsAudioYoutubeDescriptionAudioTrack)
        }
		.listRowBackground(theme.primaryBackgroundColor)

        Section {
            Toggle(isOn: preferences.$audioTiktokFullAudio, label: {
                Text(L10n.settingsAudioTiktokTitleFullAudio)
            })
        } header: {
            Text(L10n.tiktok)
        } footer: {
            Text(L10n.settingsAudioTiktokDescriptionFullAudio)
        }
		.listRowBackground(theme.primaryBackgroundColor)
    }

    @ViewBuilder
    var otherSegment: some View {
        Section(L10n.theme) {
            ForEach(availableColorsSets, id: \.id) { colorSetCouple in
				SelectionButton(title: colorSetCouple.setName.rawValue, 
								isSelected: theme.selectedSet == colorSetCouple.setName) {
					theme.setColor(withName: colorSetCouple.setName, colorScheme: colorScheme)
				}
            }
        }
		.listRowBackground(theme.primaryBackgroundColor)

		Section {
            if MailComposerView.canSendEmail() {
                Button(L10n.sendLogFileTitle) {
                    viewModel.loadLogFiles { emailData in
                        router.presented = .mail(emailData: emailData)
                    }
                }
				.tint(theme.tintColor)
            }
		}
		.listRowBackground(theme.primaryBackgroundColor)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserPreferences.shared)
        .environmentObject(Theme.shared)
        .environment(Router())
}
