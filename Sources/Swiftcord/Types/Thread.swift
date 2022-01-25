//
//  Thread.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2022-01-04.
//  Copyright © 2022 Noah Pistilli. All rights reserved.
//

import Foundation

public class ThreadChannel: TextChannel, GuildChannel, Updatable {
    // MARK: Properties

    /// Parent class
    public weak var swiftcord: Swiftcord?
        
    public let archiveTimestamp: Date?
    
    /// Time in seconds the thread will archive since the last message
    public let autoArchiveDuration: Date?
    
    /// Guild object for this channel
    public var guild: Guild? {
      return self.swiftcord?.getGuild(for: id)
    }
    
    /// ID of the thread
    public let id: Snowflake
    
    /// If the thread is archived
    public let isArchived: Bool?
    
    /// If the thread is locked
    public let isLocked: Bool?
    
    /// Last message sent's ID
    public let lastMessageId: Snowflake?
    
    /// Number of members in a thread; stops counting at 50
    public let memberCount: Int?
    
    /// Number of messages in a thread; stops counting at 50
    public let messageCount: Int?
    
    /// Name of the thread
    public let name: String?
    
    /// ID of the member who created the thread
    public let ownerId: Snowflake?
    
    /// Channel that the thread was created in
    public let parentId: Snowflake?
    
    /// How long the thread's slow mode is set to
    public let rateLimitPerUser: Int?
    
    /// Type of thread
    public let type: ChannelType
    
    // Stuff for conformance to GuildChannel
    public var category: GuildCategory?
    
    public var permissionOverwrites = [Snowflake : Overwrite]()
    
    public var position: Int?
    
    // MARK: Initializer

    /**
     Creates a GuildText structure

     - parameter swiftcord: Parent class
     - parameter json: JSON represented as a dictionary
    */
    init(_ swiftcord: Swiftcord, _ json: [String: Any]) {
        self.swiftcord = swiftcord
        
        if let threadMetaData = json["thread_metadata"] as? [String:Any] {
            self.archiveTimestamp = threadMetaData["archive_timestamp"] as? Date
            self.autoArchiveDuration = threadMetaData["auto_archive_duration"] as? Date
            self.isArchived = threadMetaData["archived"] as? Bool
            self.isLocked = threadMetaData["locked"] as? Bool
        } else {
            self.archiveTimestamp = nil
            self.autoArchiveDuration = nil
            self.isArchived = nil
            self.isLocked = nil
        }
        
        self.id = Snowflake(json["id"])!
        
        if let realLastMessageId = json["last_message_id"] as? String {
            self.lastMessageId = Snowflake(realLastMessageId)!
        } else {
            self.lastMessageId = nil
        }
        
        self.memberCount = json["member_count"] as? Int
        self.messageCount = json["message_count"] as? Int
        
        self.name = json["name"] as? String
        
        if let ownerId = json["owner_id"] {
            self.ownerId = Snowflake(ownerId)!
        } else {
            self.ownerId = nil
        }
        
        self.parentId = Snowflake(json["parent_id"])!
        
        self.rateLimitPerUser = json["rate_limit_per_user"] as? Int
        
        self.type = ChannelType(rawValue: json["type"] as! Int)!
        
        // Init values that will always be nil
        self.category = nil
        self.position = nil
        
        // Add the newly created or edited thread to the Guild's dict
        if let guildId = Snowflake(json["guild_id"]) {
            if let guild = swiftcord.guilds[guildId] {
                guild.channels[self.id] = self
            }
        }
    }
    
    
    func update(_ json: [String: Any]) {
        
    }
}
