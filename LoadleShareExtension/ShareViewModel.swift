//
//  ShareViewModel.swift
//  LoadleShareExtension
//
//  Created by Luca Archidiacono on 12.02.2024.
//

import Environments
import Foundation
import Logger
import Models
import REST
import UniformTypeIdentifiers

@MainActor
final class ShareViewModel {
    enum Error: Swift.Error, CustomStringConvertible {
        case notReachable(URL)
        case notSupported(URL)
        case notAbleToLoad(registeredTypeIdentifiers: [String])
        case noAttachamentsFound(title: NSAttributedString?, userInfo: [AnyHashable: Any]?)

        var description: String {
            let description = "\(type(of: self))."
            switch self {
            case let .notReachable(url):
                return "\(description)notReachable: Was not able to reach the provided URL: \(url)"
            case let .notSupported(url):
                return "\(description)notSupported: The provided URL does not match a supported service: \(url)"
            case let .notAbleToLoad(registeredTypeIdentifiers):
                return "\(description)notAbleToLoad: The ItemProvider only supports the following registeredTypeIdentifiers: \(registeredTypeIdentifiers)"
            case let .noAttachamentsFound(title, userInfo):
                return "\(description)noAttachamentsFound: No attachements were found inside the NSExtensionItem. Title: \(title ?? NSAttributedString(string: "")), UserInfo: \(userInfo ?? [:])"
            }
        }
    }

    public init() {}

    public func handleExtension(_ item: NSExtensionItem) async {
        do {
            guard let itemProvider = item.attachments?.first as? NSItemProvider else {
                throw Error.noAttachamentsFound(title: item.attributedTitle, userInfo: item.userInfo)
            }

            guard let url = try await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL else {
                throw Error.notAbleToLoad(registeredTypeIdentifiers: itemProvider.registeredTypeIdentifiers)
            }

            try await download(url: url)
        } catch {
            log(.error, error)
        }
    }

    private func download(url: URL) async throws {
        guard let mediaService = MediaService.allCases.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
            throw Error.notSupported(url)
        }

        let metadata = try await MetadataService.shared.fetch(using: url)

        guard let url = metadata.url else {
            throw Error.notReachable(url)
        }

        /// We need to first fetch the new url from the metada.
        /// Reason for it has to do with the fact that URL's coming from iMessage or copying using third party apps (such as the in house Reddit App), provides an URL which is not recognised by the Cobalt API.
        /// While using the URL and passing it to the MetaDataService, we should get the original URL (one which is visible by using the normal desktop browser).
        let cobaltRequest = DataTransformer.Request.transform(
            url: url,
            mediaService: mediaService,
            videoYoutubeCodec: UserPreferences.shared.videoYoutubeCodec,
            videoDownloadQuality: UserPreferences.shared.videoDownloadQuality,
            audioFormat: UserPreferences.shared.audioFormat,
            audioOnly: false,
            videoTiktokWatermarkDisabled: UserPreferences.shared.videoTiktokWatermarkDisabled,
            audioTiktokFullAudio: UserPreferences.shared.audioTiktokFullAudio,
            audioMute: UserPreferences.shared.audioMute,
            audioYoutubeTrack: UserPreferences.shared.audioYoutubeTrack,
            videoTwitterConvertGifsToGif: UserPreferences.shared.videoTwitterConvertGifsToGif,
            videoVimeoDownloadType: UserPreferences.shared.videoVimeoDownloadType
        )
        let request = REST.HTTPRequest(host: "co.wuk.sh", path: "/api/json", method: .post, body: REST.JSONBody(cobaltRequest))

        let response = try await REST.Loader.shared.load(using: request)
        let cobaltResponse: POSTCobaltResponse = try response.decode()

        // If contains picker, then download everything
        if let streamURL = cobaltResponse.url {
            await DownloadService.shared.download(using: url, streamURL: streamURL, mediaService: mediaService, metadata: metadata)
        } else {
            await withTaskGroup(of: Void.self) { group in
                if let audioStream = cobaltResponse.audio {
                    group.addTask {
                        await DownloadService.shared.download(using: url, streamURL: audioStream, mediaService: mediaService, metadata: metadata)
                    }
                }

                for picker in cobaltResponse.picker {
                    group.addTask {
                        await DownloadService.shared.download(using: url, streamURL: picker.url, mediaService: mediaService, metadata: metadata)
                    }
                }
            }
        }
    }
}
