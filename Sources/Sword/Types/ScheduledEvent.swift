//
//  ScheduledEvent.swift
//  Sword
//
//  Created by Noah Pistilli on 2022-01-04.
//

import Foundation

public struct ScheduledEvent {
    /// Channel the event will be hosted in. `nil` if type is external.
    public let channelId: Snowflake?
    
    /// User that created the event
    public let creator: User?
    
    /// Description of the event
    public let description: String?
    
    /// The ID of an entity associated with the event
    public let entityId: Snowflake?
    
    /// Type of scheduled event
    public let eventType: ScheduledEvent.EntityType
    
    /// ID of the scheduled event
    public let id: Snowflake?
    
    /// Location of the event. Required if this an external event
    public let location: String?
    
    /// Amount of members that subscribed to the event
    public let memberCount: Int?
    
    /// Name of the event
    public let name: String
    
    /// Time the event is supposed to start
    public let scheduledStartTime: Date?
    
    /// Time the event is supposed to end
    public let scheduledEndTime: Date?
    
    /// Current status of the event
    public let status: ScheduledEvent.Status
    
    // MARK: Initializers
    init(_ sword: Sword, _ json: [String:Any]) {
        if let channelId = json["channel_id"] as? String {
            self.channelId = Snowflake(channelId)!
        } else {
            self.channelId = nil
        }
        
        
        if let user = json["creator"] as? [String:Any] {
            self.creator = User(sword, user)
        } else {
            self.creator = nil
        }
        
        self.description = json["description"] as? String
        
        self.entityId = Snowflake(json["entity_id"])
        
        self.eventType = ScheduledEvent.EntityType(rawValue: json["entity_type"] as! Int)!
        
        self.id = Snowflake(json["guild_id"])
        
        self.location = ""
        
        self.memberCount = json["user_count"] as? Int
        
        self.name = json["name"] as! String
        
        self.scheduledStartTime = json["scheduled_start_time"] as? Date
        
        self.scheduledEndTime = json["scheduled_end_time"] as? Date
        
        self.status = ScheduledEvent.Status(rawValue: json["status"] as! Int)!
    }
    
    public init
    (
        channelId: String? = nil,
        name: String,
        description: String? = nil,
        location: String? = nil,
        type: ScheduledEvent.EntityType,
        startTime: Date,
        endTime: Date? = nil
    ) {
        if let channelId = channelId {
            self.channelId = Snowflake(channelId)!
        } else {
            self.channelId = nil
        }
        
        self.creator = nil
        
        self.description = description
        
        self.entityId = nil
        
        self.eventType = type
        
        self.id = nil
        
        self.location = location
        
        self.memberCount = nil
        
        self.name = name
        
        self.scheduledStartTime = startTime
        
        self.scheduledEndTime = endTime
        
        self.status = .active
    }
}

public extension ScheduledEvent {
    /// Status of a `ScheduledEvent`
    enum Status: Int {
        /// Event is scheduled to happen
        case scheduled = 1
        
        /// Event is currently taking place
        case active
        
        /// Event has finished
        case completed
        
        /// Event was canceled
        case canceled
    }
    
    /// Type of `ScheduledEvent`
    enum EntityType: Int {
        /// The event is taking place in a stage channel
        case stage = 1
        
        /// The event is taking place in a voice channel
        case voice
        
        /// The event it taking place outside of Discord
        case external
    }
}
