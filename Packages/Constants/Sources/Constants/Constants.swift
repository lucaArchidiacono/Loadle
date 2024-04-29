//
//  Constants.swift
//
//
//  Created by Luca Archidiacono on 14.02.2024.
//

public enum Constants {
	public enum Details {
		public static let email = "support@loadle.app"
	}
	public enum InApp {
		public static let apiKey = "appl_NUGLwtWxjLDfZSQDLrlxYipQxeG"
		public static let entitlementID = "Plus"
	}
	public enum Downloads {
		public static let identifier: String = "io.lucaa.Environment.Service.Download"
	}
    public enum Notifications {
        public static let download: String = "io.lucaa.Constants.Notifications.Download"
    }

    public enum URLRegex: String, CaseIterable {
        case bilibili = #"(?:https?:\/\/)?(?:www\.)?bilibili\.(?:com|tv)\/"#
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

	public enum Domain: String, CaseIterable {
		case bilibili = "bilibili.com"
		case instagram = "instagram.com"
		case okVideo = "ok.ru"
		case pinterest = "pinterest.com"
		case reddit = "reddit.com"
		case rutube = "rutube.ru"
		case soundcloud = "soundcloud.com"
		case streamable = "streamable.com"
		case tiktok = "tiktok.com"
		case tumblr = "tumblr.com"
		case twitchClips = "clips.twitch.tv"
		case twitter = "twitter.com"
		case vimeo = "vimeo.com"
		case vineArchive = "vine.co"
		case vkVideos = "vk.com"
		case youtube = "youtube.com"
	}

}
