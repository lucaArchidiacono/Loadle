//
//  Constants.swift
//
//
//  Created by Luca Archidiacono on 14.02.2024.
//

public enum Constants {
    public enum Notifications {
        public static let download: String = "io.lucaa.Constants.Notifications.Download"
    }

    public enum URLRegex: String, CaseIterable {
        case bilibili = #"(?:https?:\/\/)?(?:www\.)?bilibili\.com\/"#
        case instagram = #"(?:https?:\/\/)?(?:www\.)?instagram\.com\/"#
        case okVideo = #"(?:https?:\/\/)?(?:www\.)?ok\.ru\/"#
        case pinterest = #"(?:https?:\/\/)?(?:www\.)?pinterest\.(?:com|co\.uk)\/"#
        case reddit = #"(?:https?:\/\/)?(?:www\.)?reddit\.com\/"#
        case rutube = #"(?:https?:\/\/)?(?:www\.)?rutube\.ru\/"#
        case soundcloud = #"(?:https?:\/\/)?(?:www\.)?soundcloud\.com\/"#
        case streamable = #"(?:https?:\/\/)?(?:www\.)?streamable\.com\/"#
        case tiktok = #"(?:https?:\/\/)?(?:www\.)?tiktok\.com\/"#
        case tumblr = #"(?:https?:\/\/)?(?:www\.)?tumblr\.com\/"#
        case twitchClips = #"(?:https?:\/\/)?(?:www\.)?clips\.twitch\.tv\/"#
        case twitter = #"(?:https?:\/\/)?(?:www\.)?twitter\.com\/"#
        case vimeo = #"(?:https?:\/\/)?(?:www\.)?vimeo\.com\/"#
        case vineArchive = #"(?:https?:\/\/)?(?:www\.)?vine\.co\/"#
        case vkVideos = #"(?:https?:\/\/)?(?:www\.)?vk\.com\/"#
        case youtube = #"(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/|youtu\.be\/)"#
    }
}
