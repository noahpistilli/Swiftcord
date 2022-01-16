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
        validateUrl(url: url)

        self.url = url
    }

    private func validateUrl(url: String?) {
        // If URL is nil then we can safely ignore
        if url == nil {
            return
        }

        if !url!.contains("https://twitch.tv/") || !url!.contains("https://youtube.com/") {
            print("bruh")
        }
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
