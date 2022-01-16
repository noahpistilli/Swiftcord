//
//  Stage.swift
//  Sword
//
//  Created by Noah Pistilli on 2022-01-09.
//

import Foundation

/// Represents a Stage instance inside a Stage Channel
public struct Stage {
    /// Main class
    public let sword: Sword
    
    /// ID of the stage channel
    public let channelID: Snowflake
    
    /// Guild this stage instance is from
    public var guild: Guild? {
        return self.sword.getGuild(for: channelID)
    }
    
    /// ID of the stage instance
    public let id: Snowflake
    
    /// Whether or not Stage Discovery is disabled
    public var isDiscoveryDisabled: Bool
    
    public var privacyLevel: StagePrivacyLevel
    
    /// Topic of the stage channel
    public let topic: String
    
    init(_ sword: Sword, data: [String:Any]) {
        self.sword = sword
        
        self.channelID = Snowflake(data["channel_id"])!
        self.id = Snowflake(data["id"])!
        self.isDiscoveryDisabled = data["discoverable_disabled"] as! Bool
        self.privacyLevel = StagePrivacyLevel(rawValue: data["privacy_level"] as! Int)!
        self.topic = data["topic"] as! String
    }
}

/// Privacy Level of the stage instance
public enum StagePrivacyLevel: Int {
    /// Deprecated but the docs still show it
    case `public` = 1
    
    /// Can only be accessed by members of the guild; default
    case guildOnly
}
