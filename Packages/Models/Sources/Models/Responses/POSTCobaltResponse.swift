//
//  POSTCobaltResponse.swift
//  Loadle
//
//  Created by Luca Archidiacono on 06.02.2024.
//

import Foundation

public struct POSTCobaltResponse: Decodable {
    public let status: POSTCobaltStatusResponse
    public let text: String?
    public let url: URL?
    public let pickerType: String?
    public let picker: [POSTCobaltPickerItemResponse]
    public let audio: URL?

    enum CodingKeys: CodingKey {
        case status
        case text
        case url
        case pickerType
        case picker
        case audio
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(POSTCobaltResponse.POSTCobaltStatusResponse.self, forKey: .status)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        pickerType = try container.decodeIfPresent(String.self, forKey: .pickerType)
        picker = try container.decodeIfPresent([POSTCobaltResponse.POSTCobaltPickerItemResponse].self, forKey: .picker) ?? []

        do {
            audio = try container.decodeIfPresent(URL.self, forKey: .audio)
        } catch {
            audio = nil
        }
    }

    public enum POSTCobaltStatusResponse: String, Decodable {
        case error
        case redirect
        case stream
        case success
        case rateLimit
        case picker

        enum CodingKeys: String, CodingKey {
            case error
            case redirect
            case stream
            case success
            case rateLimit = "rate-limit"
            case picker
        }
    }

    public struct POSTCobaltPickerItemResponse: Decodable {
        public let url: URL
    }
}
