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
import Logger
import Constants

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL

    private enum Segment: String, CaseIterable {
        case video
        case audio
        case other
		#if DEBUG
		case logs
		#endif

        var rawValue: String {
            switch self {
            case .video: return L10n.video
            case .audio: return L10n.audio
            case .other: return L10n.other
			#if DEBUG
			case .logs: return "Logs"
			#endif
            }
        }
    }

    @EnvironmentObject private var preferences: UserPreferences
    @Environment(Router.self) private var router: Router
	@Environment(AppState.self) private var appState

    @State private var viewModel: SettingsViewModel = .init()
    @State private var selected: Segment = .video
	@State private var isLoadingLogs = false

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

			if !appState.hasEntitlement {
				SubscriptionSectionView {
					router.presented = .paywall
				}
			}

            switch selected {
            case .video:
                videoSegment
            case .audio:
                audioSegment
            case .other:
                otherSegment
			#if DEBUG
			case .logs:
				logsSegment
			#endif
            }
        }
        .toolbar {
            DoneToolbar(placement: .topBarTrailing) {
                dismiss()
            }
        }
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
//		.listRowBackground(theme.secondaryBackgroundColor)
    }

    @ViewBuilder
    var otherSegment: some View {
//        Section(L10n.theme) {
//            ForEach(availableColorsSets, id: \.id) { colorSetCouple in
//				SelectionButton(title: colorSetCouple.setName.rawValue, 
//								isSelected: theme.selectedSet == colorSetCouple.setName) {
//					theme.setColor(withName: colorSetCouple.setName, colorScheme: colorScheme)
//				}
//            }
//        }
//		.listRowBackground(theme.secondaryBackgroundColor)

		Section(L10n.upcomingFeaturesTitle) {
			Text(L10n.upcomingFeaturesInAppPlayerTitle)
				.font(.headline)
				.listRowSeparator(.hidden)
			Text(L10n.upcomingFeaturesInAppPlayerMessage)
				.font(.footnote)
				.listRowSeparator(.visible)
			Text(L10n.upcomingFeaturesShareExtensionDownloadTitle)
				.font(.headline)
				.listRowSeparator(.hidden)
			Text(L10n.upcomingFeaturesShareExtensionDownloadMessage)
				.font(.footnote)
		}
		
		Section(L10n.onboardingPrivacyPolicyTitle) {
			Text(L10n.onboardingPrivacyPolicyDescription)
		}

		Section {
			Button(
				action: {
					guard let writeReviewURL = URL(string: Constants.Details.appFeedbackURL) else {
						fatalError("Expected valid URL")
					}

					openURL(writeReviewURL)
				},
				label: {
					Text(L10n.settingsOthersCustomerSupportSectionLeaveReviewTitle)
				}
			)
            if MailComposerView.canSendEmail() {
				Button(
					action: {
						isLoadingLogs = true
						Task {
							let emailData = await viewModel.loadLogFiles()
							isLoadingLogs = false
							router.presented = .mail(emailData: emailData)
						}
					},
					label: {
						ZStack {
							Text(L10n.sendLogFileTitle).opacity(isLoadingLogs ? 0 : 1)

							if isLoadingLogs {
								ProgressView()
							}
						}
					}
				)
				.disabled(isLoadingLogs)
            }
		} header: {
			Text(L10n.settingsOthersCustomerSupportSectionTitle)
		} footer: {
			Text(L10n.settingsOthersCustomerSupportSectionFooter(Constants.Details.email))
		}
    }

	#if DEBUG
	@ViewBuilder
	var logsSegment: some View {
		ForEach(viewModel.logStreams, id: \.self) { log in
			Text(log)
		}
	}
	#endif
}

#Preview {
    SettingsView()
        .environmentObject(UserPreferences.shared)
//        .environmentObject(Theme.shared)
        .environment(Router())
		.environment(AppState.shared)
}
