//
//  SettingsView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import Environments
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

	@State private var viewModel: SettingsViewModel = SettingsViewModel()
	@State private var selected: Segment = .video

	var body: some View {
		List {
			Section {
				Picker("", selection: $selected) {
					ForEach(Segment.allCases, id: \.self) { segment in
						Text(segment.rawValue)
					}
				}
				.pickerStyle(.segmented)
				.listRowBackground(Color.clear)
				.listRowInsets(EdgeInsets())
			}

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
		Section {
			Toggle(isOn: preferences.$videoTiktokWatermarkDisabled, label: {
				Text(L10n.settingsVideoTiktokTitleDisableWatermark)
			})
		} header: {
			Text(L10n.tiktok)
		}
		Section {
			Toggle(isOn: preferences.$videoTwitterConvertGifsToGif, label: {
				Text(L10n.settingsVideoTwitterTitleConvertGifsToGif)
			})
		} header: {
			Text(L10n.twitter)
		} footer: {
			Text(L10n.settingsVideoTwitterDescriptionConvertGifsToGif)
		}
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
		Section {
			Toggle(isOn: preferences.$audioMute, label: {
				Text(L10n.settingsAudioMuteTitle)
			})
		} footer: {
			Text(L10n.settingsAudioMuteDescription)
		}
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

		Section {
			Toggle(isOn: preferences.$audioTiktokFullAudio, label: {
				Text(L10n.settingsAudioTiktokTitleFullAudio)
			})
		} header: {
			Text(L10n.tiktok)
		} footer: {
			Text(L10n.settingsAudioTiktokDescriptionFullAudio)
		}
	}

	@ViewBuilder
	var otherSegment: some View {
		Section(L10n.theme) {
		ForEach(availableColorsSets, id: \.id) { colorSetCouple in
				Button {
					theme.setColor(withName: colorSetCouple.setName, colorScheme: colorScheme)
				} label: {
					HStack {
						Text(colorSetCouple.setName.rawValue)
						Spacer()
						if theme.selectedSet == colorSetCouple.setName {
							Image(systemName: "checkmark")
								.foregroundStyle(theme.tintColor)
						}
					}
				}
				.tint(colorScheme == .dark ? .white : .black)
		}

			if MailComposerView.canSendEmail() {
				Button(L10n.sendLogFileTitle) {
					viewModel.loadLogFiles { emailData in
						router.presented = .mail(emailData: emailData)
					}
				}
			}
		}
	}
}

#Preview {
	SettingsView()
		.environmentObject(UserPreferences.shared)
		.environmentObject(Theme.shared)
		.environment(Router())
}
