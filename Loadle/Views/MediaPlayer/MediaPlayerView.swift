//
//  MediaPlayerView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 02.03.2024.
//

import Foundation
import SwiftUI
import Models
import AVKit
import Environments

@MainActor
struct MediaPlayerView: View {
    @Environment(PlaylistService.self) private var playlistService: PlaylistService
    @Environment(Router.self) private var router: Router
    
	@State private var showControls: Bool = false
	@State private var showSkipForward: Bool = false
	@State private var showSkipBackward: Bool = false
	@State private var scrollPosition: PlaylistService.Item.ID?

    var body: some View {
        ZStack {
            scrollView
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    
    @ViewBuilder
    var scrollView: some View {
        ScrollView {
			LazyVStack(spacing: 0) {
				ForEach(playlistService.playlist, id: \.id) { playlistItem in
					assetView
						.id(playlistItem.id)
				}
			}
			.scrollTargetLayout()
        }
		.scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition)
        .scrollTargetBehavior(.paging)
        .ignoresSafeArea()
        .onAppear {
            scrollPosition = playlistService.currentItem?.id
        }
        .onChange(of: scrollPosition) { oldValue, newValue in
            if playlistService.prevItem?.id == newValue {
				playlistService.prev()
            } else if playlistService.nextItem?.id == newValue {
				playlistService.next()
            }
        }
    }
    
    @ViewBuilder
    var assetView: some View {
        ZStack {
            if let currentItem = playlistService.currentItem {
				switch currentItem.type {
				case .assetPlayer(let playerItemWrapper):
					playerView(using: playerItemWrapper)
						.onAppear {
							showControls = true

							runWithAnimationAndSleep {
								showControls = false
							}
						}
				case .slides(let slides):
					slidesView(slides: slides)
						.onAppear {

							withAnimation {
								showControls = false
							}
						}
                }
            }
        }
    }
    
    @ViewBuilder
	func playerView(using playerItemWrapper: PlayerItemWrapper) -> some View {
        ZStack {
			AVPlayerView(playerItem: playerItemWrapper, player: playlistService.player)
			controlsView
		}
		.containerRelativeFrame([.horizontal, .vertical])
		.onTapGesture(count: 2) { location in
			// Double tap gesture
			let screenWidth = UIScreen.main.bounds.width
			if location.x < screenWidth / 2 {
				// Skip backwards
				playlistService.skipBackward(by: 10)
				showSkipBackward = true
				
				runWithAnimationAndSleep {
					showSkipBackward = false
				}
			} else {
				// Skip forward
				playlistService.skipForward(by: 10)
				showSkipForward = true
				
				runWithAnimationAndSleep {
					showSkipForward = false
				}
			}
			showControls = false
		}
		.onTapGesture {
			// Single tap gesture
			withAnimation {
				showControls.toggle()
			}
		}
    }
    
	@ViewBuilder
	var controlsView: some View {
		ZStack {
			if showControls || showSkipBackward || showSkipForward {
				HStack {
					Spacer()

					Button(action: {
						if showControls {
							// Go backward
							playlistService.prev()
						} else if showSkipBackward {
							// Skip backward
							playlistService.skipBackward(by: 10)
						}
					}) {
						if showControls {
							Image(systemName: "backward.end.fill")
								.font(.title)
						} else if showSkipBackward {
							Image(systemName: "backward.fill")
								.font(.title)
						}
					}
					.padding()
					.background(Color.black.opacity(0.5))
					.containerShape(Circle())
					.opacity(showControls || showSkipBackward ? 1 : .leastNonzeroMagnitude)

					Spacer()

					Button(action: {
						// Toggle play/pause
						playlistService.togglePlayPause()
					}) {
						Image(systemName: playlistService.state == .playing ? "pause.fill" : "play.fill")
							.font(.title)
					}
					.padding()
					.background(Color.black.opacity(0.5))
					.containerShape(Circle())
					.opacity(showControls ? 1 : .leastNonzeroMagnitude)

					Spacer()

					Button(action: {
						if showControls {
							// Go forward
							playlistService.next()
						} else if showSkipForward {
							// Skip forward
							playlistService.skipForward(by: 10)
						}
					}) {
						if showControls {
							Image(systemName: "forward.end.fill")
								.font(.title)
						} else if showSkipForward {
							Image(systemName: "forward.fill")
								.font(.title)
						}
					}
					.padding()
					.background(Color.black.opacity(0.5))
					.containerShape(Circle())
					.opacity(showControls || showSkipForward ? 1 : .leastNonzeroMagnitude)

					Spacer()
				}
			}
		}
		.accentColor(Color(.white))
	}

	private func runWithAnimationAndSleep(_ callback: @escaping () -> Void) {
		Task {
			try? await Task.sleep(for: .seconds(1))

			withAnimation {
				callback()
			}
		}
	}

    @ViewBuilder
    func slidesView(slides: [PlaylistService.Item.Slide]) -> some View {
        ZStack {
            ScrollView {
                LazyHStack(spacing: 0) {
					EmptyView()
                }
            }
        }
    }
}
