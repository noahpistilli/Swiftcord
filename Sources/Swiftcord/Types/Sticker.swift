//
//  Sticker.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2022-01-10.
//

import Foundation

/// Structure of a sticker object
public struct Sticker: Codable {
    /// Description of the sticker
    public let description: String?

    /// ID of the sticker
    public let id: Snowflake?

    /// If the sticker is available to use. May be false if the guild has lost boosts
    public let isAvailable: Bool?

    /// Name of the sticker
    public let name: String

    /// For non-guild stickers, the pack the sticker is from
    public let packId: Snowflake?

    /// File format of the sticker
    public let format: StickerFormat?
    
    /// Autocompletion tags for the sticker
    public let tags: String?

    /// Type of sticker
    public let type: StickerTypes?

    // MARK: Initializer

    /**
     Creates a Sticker structure from the gateway response

     - parameter json: JSON representable as a dictionary
     */
    init(_ json: [String: Any]) {
        self.description = json["description"] as? String
        self.id = Snowflake(json["id"])
        self.isAvailable = json["available"] as? Bool
        self.name = json["name"] as! String
        self.packId = Snowflake(json["pack_id"])
        self.format = StickerFormat(rawValue: json["format_type"] as! Int)
        self.tags = json["tags"] as? String
        self.type = StickerTypes(rawValue: json["type"] as! Int)
    }
    
    /**
     Creates a Sticker structure for uploading or editing

     - parameter name: Name of the sticker
     - parameter description: Description of the sticker
     - parameter tags: A string formatted like comma-seperated values for autocompletion
     */
    public init(
        name: String,
        description: String,
        tags: String
    ) {
        self.name = name
        self.description = description
        self.tags = tags
        
        self.id = nil
        self.isAvailable = nil
        self.packId = nil
        self.format = nil
        self.type = nil
    }
}

/// The types of stickers possible
public enum StickerTypes: Int, Codable {
    /// An official sticker made by Discord
    case standard = 1

    /// Stickers found in a guild
    case guild
}

/// The possible file format for stickers
public enum StickerFormat: Int, Codable {
    case png = 1
    case apng
    case lottie
}
