//
//  PlaylistService.swift
//
//
//  Created by Luca Archidiacono on 16.03.2024.
//

import Foundation
import AVFoundation
import Logger
import Models
import MediaPlayer
import Fundamentals
import LinkPresentation
import Combine
import AsyncQueue

enum NowPlayableInterruption {
	case began, ended(Bool), failed(Error)
}

struct DynamicMetaData {
    let rate: Float
    let position: Float
    let duration: Float
}

public struct PlayerItemWrapper: Identifiable, Equatable {
    public let id = UUID()
    public let assetURL: URL
    public let playerItem: AVPlayerItem
    public let metadata: MetaData
    public let loop: Bool
    public let enableBackground: Bool

    public struct MetaData: Equatable {
        public let mediaType: MPNowPlayingInfoMediaType
        public let title: String
		public let imageProvider: NSItemProvider?
    }
}

@MainActor
@Observable
public final class PlaylistService {
	public enum PlayerState {
		case stopped
		case playing
		case paused
	}

	public struct Item: Hashable, Identifiable, Equatable {
		public enum Slide: Hashable, Equatable {
			case image(UIImage)
			case video(PlayerItemWrapper)

			public func hash(into hasher: inout Hasher) {
				hasher.combine(self)
			}
		}
        
        public enum `Type`: Equatable {
            case assetPlayer(PlayerItemWrapper)
            case slides([Slide])
        }

        public let id: URL
        public let type: `Type`

        init(id: URL, type: `Type`) {
            self.id = id
            self.type = type
		}
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
	private let queue = FIFOQueue()
	private var subscriptions = Set<AnyCancellable>()
	private var playerLooper: AVPlayerLooper?
	private var isInterrupted: Bool = false
	private var playerItemWrappers: [PlayerItemWrapper] = []

    public private(set) var currentItem: Item?
    public private(set) var playlist: Array<Item> = []
	public private(set) var state: PlayerState = .stopped

	public var hasPrev: Bool { prevItem != currentItem }
	public var hasNext: Bool { nextItem != currentItem }
	public var prevItem: Item? {
        guard let currentItem, let index = playlist.firstIndex(of: currentItem) else { return nil }
        guard index > playlist.startIndex else { return nil }
        let prevIndex = playlist.index(before: index)
        return playlist[prevIndex]
	}
	public var nextItem: Item? {
		guard let currentItem, let index = playlist.firstIndex(of: currentItem) else { return nil }
        guard index < playlist.index(before: playlist.endIndex) else { return nil }
        let nextIndex = playlist.index(after: index)
        return playlist[nextIndex]
	}

	public var player: AVQueuePlayer

	public static let shared = PlaylistService()

	init() {
		let player = AVQueuePlayer()
		player.allowsExternalPlayback = true
		self.player = player

		configureAudioSession()
		configureCommandCenter()
		observe()
	}

	private func configureAudioSession() {
		do {
			let session = AVAudioSession.sharedInstance()
			try session.setCategory(.playback, mode: .default)
		} catch {
			log(.error, error)
		}
	}

	private func configureCommandCenter() {
		MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [10.0]
		MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [10.0]

		MPRemoteCommandCenter.shared().skipBackwardCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { event in
			log(.debug, "Skip backward command was executed")
			guard let skipCommand = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
			self.seek(to: skipCommand.interval)
			return .success
		}
		MPRemoteCommandCenter.shared().skipForwardCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { event in
			log(.debug, "Skip forward command was executed")
			guard let skipCommand = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
			self.seek(to: skipCommand.interval)
			return .success
		}
		MPRemoteCommandCenter.shared().changePlaybackPositionCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { event in
			log(.debug, "Change playbackPosition command was executed")
			guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
			self.seek(to: event.positionTime)
			return .success
		}
		MPRemoteCommandCenter.shared().togglePlayPauseCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { event in
			log(.debug, "Toggle playPause command was executed")
			self.togglePlayPause()
			return .success
		}
		MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().playCommand.addTarget { event in
			log(.debug, "Play command was executed")
			self.play()
			return .success
		}
		MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().pauseCommand.addTarget { event in
			log(.debug, "Pause command was executed")
			self.pause()
			return .success
		}
		MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { event in
			log(.debug, "Next track command was executed")
			self.next()
			return .success
		}
		MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { event in
			log(.debug, "Previous track command was executed")
			self.prev()
			return .success
		}
		MPRemoteCommandCenter.shared().changePlaybackRateCommand.removeTarget(nil)
		MPRemoteCommandCenter.shared().changePlaybackRateCommand.addTarget { event in
			log(.debug, "Change playback rate command was executed")
			guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
			self.setPlaybackRate(event.playbackRate)
			return .success
		}
	}

	private func observe() {
		player.publisher(for: \.status)
			.removeDuplicates()
			.sink { status in
				switch status {
				case .readyToPlay:
					/// A value that indicates the player is ready to media.
					log(.debug, "Current AVQueuePlayer status: `readyToPlay`")
					break
				case .failed:
					/// A value that indicates the player can no longer play media due to an error.
					log(.error, "Current AVQueuePlayer status: `failed`")
					break
				case .unknown:
					/// A value that indicates a player hasn’t attempted to load media for playback.
					log(.debug, "Current AVQueuePlayer status: `unknown`")
					break
				@unknown default:
					fatalError("Not handeled new state: \(status)")
				}
			}
			.store(in: &subscriptions)

		player.publisher(for: \.currentItem, options: [.initial, .new])
			.removeDuplicates()
			.sink { [unowned self] currentItem in
				if let currentItem {
					log(.debug, "New currentItem: \(currentItem)")
				}
				self.handlePlayerItemChange()
			}
			.store(in: &subscriptions)

		player.publisher(for: \.rate, options: [.initial, .new])
			.removeDuplicates()
			.sink { [unowned self] newRate in
				log(.debug, "New Rate: \(newRate)")
				self.handlePlaybackChange()
			}
			.store(in: &subscriptions)

		player.publisher(for: \.currentItem?.status, options: [.initial, .new])
			.removeDuplicates()
			.sink { [unowned self] status in
				if let status {
					log(.debug, "New currentItem status: \(status)")
				}
				self.handlePlaybackChange()
			}
			.store(in: &subscriptions)

		NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
			.receive(on: RunLoop.main)
			.sink { [unowned self] notification in
				log(.debug, "Interruption Notification was called: \(notification)")
				guard let userInfo = notification.userInfo,
					  let interruptionTypeUInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
					  let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeUInt) else {
					return
				}

				switch interruptionType {
				case .began:
					self.handleInterrupt(with: .began)
				case .ended:
					do {
						try AVAudioSession.sharedInstance().setActive(true)

						if let optionsUInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
						   AVAudioSession.InterruptionOptions(rawValue: optionsUInt).contains(.shouldResume) {
							self.handleInterrupt(with: .ended(true))
						} else {
							self.handleInterrupt(with: .ended(false))
						}
					} catch {
						self.handleInterrupt(with: .failed(error))
					}
				@unknown default:
					fatalError("Not handeled new state: \(interruptionType)")
				}

			}
			.store(in: &subscriptions)
	}

	private func handleInterrupt(with interruption: NowPlayableInterruption) {
		switch interruption {
		case .began:
			isInterrupted = true
		case .ended(let shouldPlay):
			isInterrupted = false
			switch state {
			case .stopped:
				break
			case .playing where shouldPlay:
				player.play()
			case .playing:
				state = .paused
			case .paused:
				break
			}

		case .failed(let error):
			log(.error, error)
			optOut()
		}
	}

	public func select(_ current: MediaAssetItem, playlist: [MediaAssetItem]) {
		let newPlaylist: [Item] = playlist.compactMap { self.transform($0) }
		guard let newCurrent = newPlaylist.first(where: { $0.id == current.id }) else { return }

		clear()

		switch newCurrent.type {
		case .assetPlayer(let playerItemWrapper):
			enqueue(using: playerItemWrapper)
		case .slides(let slides):
			break
		}

		self.playlist = newPlaylist
		self.currentItem = newCurrent

		activate()
		play()

		guard let nextItem else { return }

		switch nextItem.type {
		case .assetPlayer(let playerItemWrapper):
			enqueue(using: playerItemWrapper)
		case .slides(let slides):
			break
		}
	}
}

// MARK: - Player API
extension PlaylistService {
	/// Go to the previous item.
	public func prev() {
		guard let prevItem else { return }
		switch prevItem.type {
		case .assetPlayer(let prevPlayerItemWrapper):
			enqueue(using: prevPlayerItemWrapper)
		case .slides(let slides):
			break
		}

		dequeue()
		seek(to: .zero)

		self.currentItem = prevItem

		guard let nextItem else { return }

		switch nextItem.type {
		case .assetPlayer(let playerItemWrapper):
			enqueue(using: playerItemWrapper)
		case .slides(let slides):
			break
		}
	}

	/// Go to the next item.
	public func next() {
		guard let nextItem else { return }
		switch nextItem.type {
		case .assetPlayer:
			dequeue()
			seek(to: .zero)
		case .slides(let slides):
			break
		}

		self.currentItem = nextItem

		guard let nextItem = self.nextItem else { return }

		switch nextItem.type {
		case .assetPlayer(let playerItemWrapper):
			enqueue(using: playerItemWrapper)
		case .slides(let slides):
			break
		}
	}

	public func togglePlayPause() {
		switch state {
		case .stopped:
			play()
		case .playing:
			pause()
		case .paused:
			play()
		}
	}

	public func play() {
		switch state {
		case .stopped:
			state = .playing
			player.play()
			handlePlayerItemChange()
		case .playing:
			break
		case .playing where isInterrupted:
			state = .playing
		case .paused:
			state = .playing
			player.play()
		}
	}

	public func pause() {
		switch state {
		case .stopped:
			break
		case .playing where isInterrupted:
			state = .paused
		case .playing:
			state = .paused
			player.pause()
		case .paused:
			break
		}
	}

	public func seek(to timeInterval: TimeInterval) {
		seek(to: CMTime(seconds: timeInterval, preferredTimescale: 1))
	}

	public func skipForward(by interval: TimeInterval) {
		seek(to: player.currentTime() + CMTime(seconds: interval, preferredTimescale: 1))
	}

	public func skipBackward(by interval: TimeInterval) {
		seek(to: player.currentTime() - CMTime(seconds: interval, preferredTimescale: 1))
	}

	private func seek(to time: CMTime) {
		if case .stopped = state { return }

		player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) {
			isFinished in
			if isFinished {
				self.handlePlaybackChange()
			}
		}
	}
}

// MARK: - Metadata API
extension PlaylistService {
	/// Helper method: update Now Playing Info when the current item changes.
	private func handlePlayerItemChange() {
		guard state != .stopped else { return }

		guard let current = player.currentItem else { return }
		guard let playerItemWrapper = playerItemWrappers.first(where: { $0.playerItem == current }) else { return }

		// Set the Now Playing Info from static item metadata.
		setNowPlayingMetadata(using: playerItemWrapper.assetURL, asset: playerItemWrapper.playerItem.asset, metadata: playerItemWrapper.metadata)
	}

	/// Helper method: update Now Playing Info when playback rate or position changes.
	private func handlePlaybackChange() {
		guard state != .stopped else { return }

		guard let currentItem = player.currentItem else { return }
		guard currentItem.status == .readyToPlay else { return }

		let isPlaying = state == .playing
		let metadata = DynamicMetaData(rate: player.rate,
									   position: Float(currentItem.currentTime().seconds),
									   duration: Float(currentItem.duration.seconds))

		setNowPlayingPlaybackInfo(isPlaying: isPlaying, metadata: metadata)
	}

    /// Set playback info.
    private func setNowPlayingPlaybackInfo(isPlaying: Bool, metadata: DynamicMetaData) {
		#if os(macOS)
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
		#endif
		let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
		var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        log(.verbose, "Set playback info: rate \(metadata.rate), position \(metadata.position), duration \(metadata.duration)")
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = metadata.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = metadata.position
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = metadata.rate
		nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

		nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    /// Set per-track metadata.
	private func setNowPlayingMetadata(using assetURL: URL, asset: AVAsset, metadata: PlayerItemWrapper.MetaData) {
		let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
		var nowPlayingInfo = [String: Any]()

        log(.verbose, "Set track metadata: title \(metadata.title)")
        nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = assetURL
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = metadata.mediaType.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        nowPlayingInfo[MPMediaItemPropertyTitle] = metadata.title
		
		buildArtwork(using: asset, imageProvider: metadata.imageProvider) { artwork in
			guard let artwork else { return }
			MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size, requestHandler: { newSize in artwork.imageWith(newSize: newSize) })
		}

		nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

	private func buildArtwork(using asset: AVAsset, imageProvider: NSItemProvider?, completion: @escaping (UIImage?) -> Void) {
		if let imageProvider = imageProvider {
			buildArtwork(using: imageProvider) { [weak self] image in
				guard let image else {
					self?.buildArtwork(using: asset, completion: completion)
					return
				}
				completion(image)
			}
		} else {
			buildArtwork(using: asset, completion: completion)
		}
	}

	private func buildArtwork(using imageProvider: NSItemProvider, completion: @escaping (UIImage?) -> Void) {
		_ = imageProvider.loadTransferable(type: Data.self) { result in
			switch result {
			case .success(let data):
				completion(UIImage(data: data))
			case .failure(let error):
				log(.error, "Was not able to load image from ImageProvider for Artwork: \(error)")
				completion(nil)
			}
		}
	}

	private func buildArtwork(using asset: AVAsset, completion: @escaping (UIImage?) -> Void) {
		let generator = AVAssetImageGenerator(asset: asset)
		generator.appliesPreferredTrackTransform = true
		generator.requestedTimeToleranceBefore = .zero
		generator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)
		generator.generateCGImageAsynchronously(for: .zero) { cgImage, _, error in
			if let error {
				log(.error, "Was not able to create Artwork using AVAssetImageGenerator: \(error)")
				completion(nil)
				return
			}

			if let cgImage {
				completion(UIImage(cgImage: cgImage))
			} else {
				log(.error, "Was not able to retrieve CGImage using AVAssetImageGenerator")
				completion(nil)
			}
		}
	}
}

// MARK: - State Adjustement API
extension PlaylistService {
	private func activate() {
		do {
			try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
		} catch {
			log(.error, "Failed to activate audio session, error: \(error)")
		}
	}
	private func deactivate() {
		do {
			try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
		} catch {
			log(.error, "Failed to deactivate audio session, error: \(error)")
		}
	}
	private func enqueue(using item: PlayerItemWrapper) {
		if player.canInsert(item.playerItem, after: player.currentItem) {
			player.insert(item.playerItem, after: player.currentItem)
			playerItemWrappers.append(item)
		}
	}

	private func dequeue() {
		guard state != .stopped else { return }
		player.advanceToNextItem()
		playerItemWrappers.removeFirst()
	}

	private func setPlaybackRate(_ rate: Float) {
		if case .stopped = state { return }
		player.rate = rate
	}

	private func clear() {
		player.pause()
		player.removeAllItems()
		playerItemWrappers.removeAll()
		state = .stopped

		#if os(macOS)
		MPNowPlayingInfoCenter.default().playbackState = .stopped
		#endif
	}

	private func optOut() {
		clear()

		do {
			try AVAudioSession.sharedInstance().setActive(false)
		} catch {
			log(.error, "Failed to deactivate audio session, error: \(error)")
		}
	}
}

// MARK: - Transformation API
extension PlaylistService {
	private func transform(_ item: MediaAssetItem) -> Item? {
		if item.fileURLs.count == 1, let assetURL = item.fileURLs.first {
			// No Slide Item
			if assetURL.containsMovie {
                return transform(using: item.id, assetURL: assetURL, title: item.title, metadata: item.metadata, mediaType: .video)
			} else if assetURL.containsAudio {
                return transform(using: item.id, assetURL: assetURL, title: item.title, metadata: item.metadata, mediaType: .audio)
			} else if assetURL.containsImage {
				guard let singleImage: UIImage = transform(assetURL) else { return nil }
                return Item(id: item.id, type: .slides([.image(singleImage)]))
			}

			return nil
		} else {
			// Slide Item
			return nil
		}
	}

	private func transform(_ url: URL) -> UIImage? {
		guard let type = UTType(filenameExtension: url.pathExtension) else { return nil }

		if type.conforms(to: .gif), let gifImage = UIImage.gifImageWithURL(url) {
			return gifImage
		} else if type.conforms(to: .image), let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
			return image
		}

		return nil
	}

    private func transform(using id: URL, assetURL: URL, title: String, metadata: LPLinkMetadata, mediaType: MPNowPlayingInfoMediaType) -> Item? {
		let asset = AVAsset(url: assetURL)

		let metadata = PlayerItemWrapper.MetaData(
			mediaType: mediaType,
			title: title,
			imageProvider: metadata.imageProvider)
		let playerItem = PlayerItemWrapper(
			assetURL: assetURL,
			playerItem: AVPlayerItem(asset: asset),
			metadata: metadata,
			loop: false,
			enableBackground: true)
        return Item(id: id, type: .assetPlayer(playerItem))
	}
}
