//
//  Enums.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

/// Organize all dispatch events
enum OP: Int {
    case dispatch,
         heartbeat,
         identify,
         statusUpdate,
         voiceStateUpdate,
         resume = 6,
         reconnect,
         requestGuildMember,
         invalidSession,
         hello,
         heartbeatACK
}

/// Organize all voice dispatch events
enum VoiceOP: Int {
    case identify,
         selectProtocol,
         ready,
         heartbeat,
         sessionDescription,
         speaking,
         heartbeatACK,
         resume,
         hello,
         resumed,
         clientDisconnect = 13
}

/// Organize all websocket close codes
enum CloseOP: Int {
    case noInternet = 50,
         clean = 1000,
         goingAway = 1001,
         unexpectedServerError = 1011,
         unknownError = 4000,
         unknownOP,
         decodeError,
         notAuthenticated,
         authenticationFailed,
         alreadyAuthenticated,
         invalidSeq = 4007,
         rateLimited,
         sessionTimeout,
         invalidShard,
         shardingRequired,
         invalidAPIVersion,
         invalidIntents,
         disallowedIntents
}

/// Organize all the different http methods
enum HTTPMethod: String {
    case get = "GET",
         post = "POST",
         put = "PUT",
         patch = "PATCH",
         delete = "DELETE"
}

/// Used to determine avatar url format
public enum FileExtension: String {

    /// .gif format
    case gif

    /// .jpg format
    case jpg

    /// .png format
    case png

    /// .webp format
    case webp

}

/// Organize all ws dispatch events
public enum Event: String {

    /**
     Fired when audio data is received from voice connection
     */
    case audioData

    /**
     Fired when a channel is created
     */
    case channelCreate = "CHANNEL_CREATE"

    /**
     Fired when a channel is deleted
     */
    case channelDelete = "CHANNEL_DELETE"

    /**
     Fired when a channel adds a pin or removes a pin
     */
    case channelPinsUpdate = "CHANNEL_PINS_UPDATE"

    /**
     Fired when a channel is updated
     */
    case channelUpdate = "CHANNEL_UPDATE"

    /**
     Fired when voice connection dies (self emitted)
     */
    case connectionClose

    /**
     Fired when a shard is disconnected from the gateway
     */
    case disconnect

    /**
     Fired when a guild is available (This is not guildCreate)
     */
    case guildAvailable

    /**
     Fired when a member of a guild is banned
     */
    case guildBanAdd = "GUILD_BAN_ADD"

    /**
     Fired when a member of a guild is unbanned
     */
    case guildBanRemove = "GUILD_BAN_REMOVE"

    /**
     Fired when a guild is created
     */
    case guildCreate = "GUILD_CREATE"

    /**
     Fired when a guild is deleted
     */
    case guildDelete = "GUILD_DELETE"

    /**
     Fired when a guild's custom emojis are created/deleted/updated
     */
    case guildEmojisUpdate = "GUILD_EMOJIS_UPDATE"

    /**
     Fired when a guild updates it's integrations
     */
    case guildIntegrationsUpdate = "GUILD_INTEGRATIONS_UPDATE"

    /**
     Fired when a user joins a guild
     */
    case guildMemberAdd = "GUILD_MEMBER_ADD"

    /**
     Fired when a member leaves a guild
     */
    case guildMemberRemove = "GUILD_MEMBER_REMOVE"

    /**
     Fired when a member of a guild is updated
     */
    case guildMemberUpdate = "GUILD_MEMBER_UPDATE"

    /// :nodoc:
    case guildMembersChunk = "GUILD_MEMBERS_CHUNK"

    /**
     Fired when a role is created in a guild
     */
    case guildRoleCreate = "GUILD_ROLE_CREATE"

    /**
     Fired when a role is deleted in a guild
     ```
     */
    case guildRoleDelete = "GUILD_ROLE_DELETE"

    /**
     Fired when a role is updated in a guild
     */
    case guildRoleUpdate = "GUILD_ROLE_UPDATE"

    /**
     Fired when a guild becomes unavailable
     */
    case guildUnavailable

    /**
     Fired when a guild is updated
     */
    case guildUpdate = "GUILD_UPDATE"

    /**
     Fired when a message is created
     */
    case messageCreate = "MESSAGE_CREATE"

    /**
     Fired when a message is deleted
     */
    case messageDelete = "MESSAGE_DELETE"

    /**
     Fired when a large chunk of messages are deleted
     */
    case messageDeleteBulk = "MESSAGE_DELETE_BULK"

    /**
     Fired when a message's reactions are all removed
     */
    case messageReactionRemoveAll = "MESSAGE_REACTION_REMOVE_ALL"

    /**
     Fired when a message is updated
     */
    case messageUpdate = "MESSAGE_UPDATE"

    /**
     Fired when a payload is received through the gateway
     */
    case payload

    /**
     Fired when a user's presences is updated
     */
    case presenceUpdate = "PRESENCE_UPDATE"

    /**
     Fired when the bot is ready to receive events
     */
    case ready = "READY"

    /**
     Fired when a reaction is added to a message
     */
    case reactionAdd = "MESSAGE_REACTION_ADD"

    /**
     Fired when a reaction is removed from a message
     */
    case reactionRemove = "MESSAGE_REACTION_REMOVE"

    /// :nodoc:
    case resume = "RESUME"

    /// :nodoc:
    case resumed = "RESUMED"

    /**
     Fired when a shard becomes ready
     */
    case shardReady

    /**
     Fired when a thread is created
     */
    case threadCreate = "THREAD_CREATE"

    /**
     Fired when a thread is deleted
     */
    case threadDelete = "THREAD_DELETE"

    /**
     Fired when a thread is updated
     */
    case threadUpdate = "THREAD_UPDATE"

    /**
     Fired when someone starts typing a message
     */
    case typingStart = "TYPING_START"

    /**
     Fired when a user updates their info
     */
    case userUpdate = "USER_UPDATE"

    /**
     Fired when someone joins a voice channel
     */
    case voiceChannelJoin

    /**
     Fired when someone leaves a voice channel
     */
    case voiceChannelLeave

    /**
     Fired when someone joins/leaves/moves a voice channel
     */
    case voiceStateUpdate = "VOICE_STATE_UPDATE"

    /// :nodoc:
    case voiceServerUpdate = "VOICE_SERVER_UPDATE"

    /**
     Generic Interaction event
     This should never be handled by the user. Its soul purpose is for the library to distinguish the different types of interactions
     As they all send this event.
    */
    case interaction = "INTERACTION_CREATE"
    
    /**
     Fired when a button is clicked
     */
    case buttonEvent = "BUTTON_INTERACTION"

    /**
     Fired when a Select Menu is selected
     */
    case selectMenuEvent = "SELECT_BOX_INTERACTION"

    /**
     Fired when a slash command is used
     */
    case slashCommandEvent = "SLASH_COMMAND_INTERACTION"

    /**
     Fired when a user command is used
     */
    case userCommandEvent = "USER_COMMAND_INTERACTION"

    /**
     Fired when a message command is used
     */
    case messageCommandEvent = "MESSAGE_COMMAND_INTERACTION"
    
    /**
     Fired when a text input is used
     */
    case textInputEvent = "TEXT_INPUT_INTERACTION"
}

/// Value for Intents
public enum Intents: Int {
    /// The `guilds` intent is required for us to cache channels locally. It is also needed for many events
    // case guilds = 1

    /// Events on member join, leave and updates. This is a Privileged Intent
    case guildMembers = 2

    /// Ban events
    case guildBans = 4

    /// Emote and Stickers create, update and delete events
    case guildEmojisAndStickers = 8

    /// Events on creating, editing or deleting integrations.
    case guildIntegrations = 16

    /// Webhook events
    case guildWebhooks = 32

    /// Events on the creation or deletion of invites
    case guildInvites = 64

    /// Voice State events. Required to determine which members are in a voice channel
    case guildVoiceStates = 128

    /// Presence events. This is an extremely heavy intent! If you are trying to get information on members, use the `guildMembers` intent instead. This is a privileged Intent
    case guildPresences = 256

    /// Events on when a message in a guild is created, updated or deleted. This will become a privileged intent in 2022
    case guildMessages = 512

    /// Events on when a reaction is added to a message in a guild
    case guildMessageReactions = 1024

    /// Typing event of a member in a guild
    case guildMessageTyping = 2048

    // TODO: Figure this out
    case directMessages = 4096

    /// Events on when a reaction is added to a message in a DM
    case directMessagesReactions = 8192

    /// Typing event of a user in a DM
    case directMessagesTyping = 16384
    
    /// Required to receive full content of all messages. This is a privileged intent as of September 2022
    case messageContent = 32768

    /// Events on when an event is created, edited or deleted in a guild
    case guildScheduledEvents = 65536
}

/// Value type for statuses
public enum Status: String {

    /// Do not disturb status
    case dnd = "dnd"

    /// Away status
    case idle = "idle"

    /// Invisible/Offline status
    case offline = "offline"

    /// Online status
    case online = "online"

    // Shown as offline but really isn't
    case invisible = "invisible"
}

public enum ResponseError: Error {
    case invalidURL
    case nonSuccessfulRequest(RequestError)
    case other(RequestError)
    case unknownResponse
}

/// Permission enum to prevent wrong permission checks
public enum Permission: Int {

    /// Allows creation of instant invites
    case createInstantInvite = 0x1

    /// Allows kicking members
    case kickMembers = 0x2

    /// Allows banning members
    case banMembers = 0x4

    /// Allows all permissions and bypasses channel permission overwrites
    case administrator = 0x8

    /// Allows management and editing of channels
    case manageChannels = 0x10

    /// Allows management and editing of the guild
    case manageGuild = 0x20

    /// Allows for the addition of reactions to messages
    case addReactions = 0x40

    /// Allows for the user to view a server's audit log
    case viewAuditLog = 0x80

    /// Allows viewing of a channel. The channel will not appear for users without this permission
    case viewChannel = 0x400

    /// Allows for sending messages in a channel.
    case sendMessages = 0x800

    /// Allows for sending of /tts messages
    case sendTTSMessages = 0x1000

    /// Allows for deletion of other users messages
    case manageMessages = 0x2000

    /// Links sent by this user will be auto-embedded
    case embedLinks = 0x4000

    /// Allows for uploading images and files
    case attachFiles = 0x8000

    /// Allows for reading of message history
    case readMessageHistory = 0x10000

    /// Allows for using the @everyone tag to notify all users in a channel, and the @here tag to notify all online users in a channel
    case mentionEveryone = 0x20000

    /// Allows the usage of custom emojis from other servers
    case useExternalEmojis = 0x40000

    /// Allows for joining of a voice channel
    case connect = 0x100000

    /// Allows for speaking in a voice channel
    case speak = 0x200000

    /// Allows for muting members in a voice channel
    case muteMembers = 0x400000

    /// Allows for deafening of members in a voice channel
    case deafenMembers = 0x800000

    /// llows for moving of members between voice channels
    case moveMembers = 0x1000000

    /// Allows for using voice-activity-detection in a voice channel
    case useVad = 0x2000000

    /// Allows for modification of own nickname
    case changeNickname = 0x4000000

    /// Allows for modification of other users nicknames
    case manageNicknames = 0x8000000

    /// Allows management and editing of roles
    case manageRoles = 0x10000000

    /// Allows management and editing of webhooks
    case manageWebhooks = 0x20000000

    /// Allows management and editing of emojis
    case manageEmojis = 0x40000000

}

