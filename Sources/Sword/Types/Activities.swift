//
//  Activities.swift
//  Sword
//
//  Created by Noah Pistilli on 2021-12-16.
//

import Foundation

public struct Activities: Encodable {
    public let name: String
    public let type: Int
    public var url: String?

    public init(name: String, type: ActivityType, url: String? = nil) {
        self.name = name
        self.type = type.rawValue
        let isValidURL = validateUrl(url: url)

        if isValidURL {
            self.url = url
        } else {
            self.url = "https://www.twitch.tv/"
        }
    }

    private func validateUrl(url: String?) -> Bool {
        // If URL is nil then we can safely ignore
        if url == nil {
            return true
        }

        if !url!.contains("https://twitch.tv/") || !url!.contains("https://youtube.com/") {
            print("[Sword] URL for activities requires either a Twitch or Youtube link. There will be no link to your stream in the RPC section.")
            return false
        }
        
        return true
    }
}

public enum ActivityType: Int, Encodable {
    case playing
    case streaming
    case listening
    case watching
    case custom
    case competing
}
