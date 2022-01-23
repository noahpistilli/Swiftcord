//
//  AuditLog.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

/// Represents a guild's audit log
public struct AuditLog {
    // MARK: Properties

    /// Array of audit log entries
    public var entries = [AuditLog.Entry]()
    
    /// Array of scheduled events found in audit log
    public var guildScheduledEvents = [ScheduledEvent]()
    
    /// Array of threads found in audit log
    public var threads = [Thread]()

    /// Array of users found in audit log
    public var users = [User]()

    /// Array of webhooks found in audit log
    public var webhooks = [Webhook]()

    // MARK: Initialzer

    /**
     Creates an AuditLog structure
   
     - parameter swiftcord: Parent class to give users and webhooks
     - parameter json: Dictionary representation of audit log
     */
    init(_ swiftcord: Swiftcord, _ json: [String: [Any]]) {
        let entries = json["audit_log_entries"]!
        for entry in entries {
            self.entries.append(AuditLog.Entry(entry as! [String: Any]))
        }
        
        let events = json["guild_scheduled_events"]!
        for event in events {
            self.guildScheduledEvents.append(ScheduledEvent(swiftcord, event as! [String:Any]))
        }
        
        let threads = json["threads"]!
        for thread in threads {
            self.threads.append(Thread(swiftcord, thread as! [String : Any]))
        }

        let users = json["users"]!
        for user in users {
            self.users.append(User(swiftcord, user as! [String: Any]))
        }

        let webhooks = json["webhooks"]!
        for webhook in webhooks {
            self.webhooks.append(Webhook(swiftcord, webhook as! [String: Any]))
        }
    }
}

extension AuditLog {
    /// Representation of an individual entry in audit logs
    public struct Entry {
        // MARK: Properties

        /// Type of action that occurred
        public let actionType: AuditLog.Entry.Event

        /// Array of changes made to targetId
        public internal(set) var changes = [AuditLog.Entry.Change]()

        /// ID of the audit log entry
        public let id: Snowflake

        /// Optional entry information for certain action types
        public let options: [String: Any]

        /// User provided reason for this entry
        public let reason: String

        /// ID of the affected entity
        public let targetId: Snowflake

        /// User ID that made this change
        public let userId: Snowflake
        
        // MARK: Initializer

        /**
         Creates an AuditLogEntry structure
     
         - parameter json: Dictionary representation of the entry
         */
        init(_ json: [String: Any]) {
            self.actionType = AuditLog.Entry.Event(
                rawValue: json["action_type"] as! Int
            )!

            let changes = json["changes"] as! [[String: Any]]
            for change in changes {
                self.changes.append(AuditLog.Entry.Change(change))
            }

            self.id = Snowflake(json["id"])!
            self.options = json["options"] as! [String: Any]
            self.reason = json["reason"] as! String
            self.targetId = Snowflake(json["target_id"])!
            self.userId = Snowflake(json["user_id"])!
        }
    }
}

extension AuditLog.Entry {
    /// Specific information of changes made to targetId
    public struct Change {
        // MARK: Properties

        /// Type of audit log change
        public let key: String

        /// New value after change
        public let newValue: Any

        /// Old value before change
        public let oldValue: Any
        
        // MARK: Initializer
        /**
         Creates an AuditLogChange structure
     
         - parameter json: Dictionary representation of a change
         */
        init(_ json: [String: Any]) {
            self.key = json["key"] as! String
            self.newValue = json["new_value"]!
            self.oldValue = json["old_value"]!
        }
    }
}

extension AuditLog.Entry {
    /// Type of action that occurs for an entry
    public enum Event: Int {
        /// A guild is updated
        case guildUpdate = 1

        /// A channel is created in a guild
        case channelCreate = 10

        /// A channel is updated in a guild
        case channelUpdate

        /// A channel is deleted in a guild
        case channelDelete

        /// A channel creates a new overwrite
        case channelOverwriteCreate

        /// A channel's overwrite is updated
        case channelOverwriteUpdate

        /// A chanenl's overwrite is deleted
        case channelOverwriteDelete

        /// A member is kicked from a guild
        case memberKick = 20
        
        /// Someone decides to prune inactive members
        case memberPrune

        /// A member of a guild was banned
        case memberBanAdd

        /// A member of a guild was unbanned
        case memberBanRemove

        /// A member of a guild was updated
        case memberUpdate
      
        /// A member's role was updated
        case memberRoleUpdate
      
        /// A member was moved to another voice channel forcefully
        case memberMove
      
        /// A member was disconnected from a voice channel forcefully
        case memberDisconnect
      
        // TODO: ???
        case botAdd

        /// A role was created in a guild
        case roleCreate = 30

        /// A role was updated in a guild
        case roleUpdate

        /// A role was deleted in a guild
        case roleDelete

        /// An invite was created in a guild
        case inviteCreate = 40

        /// An invite was updated in a guild
        case inviteUpdate

        /// An invite was deleted in a guild
        case inviteDelete

        /// A webhook was created for a channel
        case webhookCreate = 50

        /// A webhook was updated for a channel
        case webhookUpdate

        /// A webhook was deleted for a channel
        case webhookDelete

        /// A custom emoji was created in a guild
        case emojiCreate = 60

        /// A custom emoji was updated in a guild
        case emojiUpdate

        /// A custom emoji was deleted in a guild
        case emojiDelete

        /// A message was deleted in a channel
        case messageDelete = 72
        
        /// Multiple messages were deleted at once
        case messageBulkDelete
        
        /// A message was pinned in a channel
        case messagePin
        
        /// A message was unpinned in a channel
        case messageUnpin
        
        /// An integration was created (Webhook, Bot)
        case integrationCreate = 80
        
        /// An integration was updated (Webhook, Bot)
        case integrationUpdate
        
        /// An integration was deleted (Webhook, Bot)
        case integrationDelete
        
        /// A stage channel was created
        case stageCreate
        
        /// A stage channel was updated
        case stageUpdate
        
        /// A stage channel was deleted
        case stageDelete
        
        /// A sticker was deleted
        case stickerCreate = 90
        
        /// A sticker was updated
        case stickerUpdate
        
        /// A sticker was deleted
        case stickerDelete
        
        /// A scheduled event was created
        case guildScheduledEventCreate = 100
        
        /// A scheduled event was updated
        case guildScheduledEventUpdate
        
        /// A scheduled event was deleted
        case guildScheduledEventDelete
        
        /// A thread was created
        case threadCreate = 110
        
        /// A thread was updated
        case threadUpdate
        
        /// A thread was deleted
        case threadDelete
    }
}
