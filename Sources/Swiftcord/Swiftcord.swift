//
//  Swiftcord.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

#if os(Linux)
import FoundationNetworking
#endif
import Foundation
import Dispatch
import Logging
import NIOCore

/// Main Class for Swiftcord
open class Swiftcord: Eventable {
    // MARK: Properties

    /// Collection of DMChannels mapped by user id
    public internal(set) var dms = [Snowflake: DM]() {
        didSet {
            guard dms.count > 10 else {
                return
            }

            dms.removeValue(forKey: dms.first!.key)
        }
    }

    /// Whether or not the global queue is locked
    var isGloballyLocked = false

    /// Intents the bot is entitled to
    var intents = 1

    /// Array of the intents the bot is entitled to
    var intentArray: [Intents] = []

    /// The queue that handles requests made after being globally limited
    lazy var globalQueue: DispatchQueue = DispatchQueue(
        label: "io.sketchmaster2001.swiftcord.rest.global"
    )

    /// Used to store requests when being globally rate limited
    var globalRequestQueue = [() -> Void]()

    /// Collection of group channels the bot is connected to
    public internal(set) var groups = [Snowflake: GroupDM]()

    /// Collections of guilds the bot is currently connected to
    public internal(set) var guilds = [Snowflake: Guild]()

    /// Global JSONEncoder
    var encoder = JSONEncoder()

    /// Event listeners with the `ListenerAdapter` class
    public var listenerAdaptors = [ListenerAdapter]()

    /// Event listeners
    public var listeners = [Event: [(Any) -> Void]]()

    var logger = Logger(label: "io.github.SketchMaster2001.Swiftcord")

    /// Optional options to apply to bot
    var options: SwiftcordOptions

    /// Initial presence of bot
    var presence: [String: Any]?

    /// Collection of Collections of buckets mapped by route
    var rateLimits = [String: Bucket]()

    /// Timestamp of ready event
    public internal(set) var readyTimestamp: Date?

    /// Global URLSession (trust me i saw it on a wwdc talk, this is legit lmfao)
    let session = URLSession(
        configuration: .default,
        delegate: nil,
        delegateQueue: OperationQueue()
    )

    /// Amount of shards to initialize
    public internal(set) var shardCount = 1

    /// Shard Handler
    lazy var shardManager = ShardManager(eventLoopGroup: self.eventLoopGroup)

    /// How many shards are ready
    var shardsReady = 0

    /// The bot token
    let token: String
    
    let eventLoopGroup: EventLoopGroup?

    /// Array of unavailable guilds the bot is currently connected to
    public internal(set) var unavailableGuilds = [Snowflake: UnavailableGuild]()

    /// Int in seconds of how long the bot has been online
    public var uptime: Int? {
        if let timestamp = self.readyTimestamp {
            return Int(Date().timeIntervalSince(timestamp))
        } else {
            return nil
        }
    }

    /// The user account for the bot
    public internal(set) var user: User?

    // MARK: Initializer

    /**
     Initializes the Swiftcord class

     - parameter token: The bot token
     - parameter options: Options to give bot (sharding, offline members, etc)
     */
    public init(token: String, options: SwiftcordOptions = SwiftcordOptions(), logger: Logger? = nil, eventLoopGroup: EventLoopGroup?) {
        self.options = options
        self.token = token
        if let logger = logger {
            self.logger = logger
        } else {
            self.logger.logLevel = .info
        }
        self.eventLoopGroup = eventLoopGroup
    }

    // MARK: Functions

    /**
     Adds events for the bot to listen to

     - parameter listeners: Classes that conform to ListenerAdapter
     */
    public func addListeners(_ listeners: ListenerAdapter...) {
        self.listenerAdaptors += listeners
    }

    /**
     Adds a reaction (unicode or custom emoji) to a message

     - parameter reaction: Unicode or custom emoji reaction
     - parameter messageId: Message to add reaction to
     - parameter channelId: Channel to add reaction to message in
     */

    public func addReaction(
        _ reaction: String,
        to messageId: Snowflake,
        in channelId: Snowflake
    ) async throws {
        _ = try await self.request(.createReaction(channelId, messageId, reaction.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!))
    }

    /**
     Bans a member from a guild

     #### Option Params ####

     - **delete-message-days**: Number of days to delete messages for (0-7)

     - parameter userId: Member to ban
     - parameter guildId: Guild to ban member in
     - parameter reason: Reason why member was banned from guild (attached to audit log)
     - parameter options: Deletes messages from this user by amount of days
     */
    public func ban(
        _ userId: Snowflake,
        from guildId: Snowflake,
        for reason: String? = nil,
        with options: [String: Any] = [:],
        then completion: ((RequestError?) -> Void)? = nil
    ) async throws {
        _ = try await self.request(.createGuildBan(guildId, userId), body: options, reason: reason)
    }

    /// Starts the bot
    public func connect() {
        // Convert all our keys to snake case
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.shardManager.swiftcord = self

        if self.options.willShard {
            Task {
                do {
                    let data = try await self.getGateway()

                    self.shardManager.gatewayUrl = "\(data["url"] as! String)/?v=9&encoding=json"
                    self.shardCount = data["shards"] as! Int

                    guard self.options.isDistributed else {
                        self.shardManager.create(self.shardCount)
                        return
                    }

                    let arguments = CommandLine.arguments

                    guard arguments.count > 1 else {
                        self.logger.error("[Swiftcord] Insufficient argument count.")
                        return
                    }

                    guard arguments.contains("--shard") else {
                        self.logger.error("[Swiftcord] Must specify shard with '--shard'")
                        return
                    }

                    guard arguments.firstIndex(of: "--shard")! != arguments.count - 1 else {
                        self.logger.error("[Swiftcord] '--shard' must not be the last argument. Correct syntax is '--shard {id here}'")
                        return
                    }

                    guard let shardId = Int(arguments[arguments.firstIndex(of: "--shard")! + 1]) else {
                        self.logger.error("[Swiftcord] Shard ID could not be recognized.")
                        return
                    }

                    self.shardManager.spawn(shardId)
                } catch ResponseError.nonSuccessfulRequest(let resp) {
                    guard resp.statusCode == 401 else {
                        sleep(3)
                        self.connect()
                        return
                    }

                    self.error("Bot token invalid.")
                    return
                }
            }
        } else {
            self.shardCount = 1

            self.shardManager.create(self.shardCount)
        }

        RunLoop.current.run()
    }

    /**
     Creates a channel in a guild

     #### Option Params ####

     - **name**: The name to give this channel
     - **type**: The type of channel to create
     - **bitrate**: If a voice channel, sets the bitrate for the voice channel
     - **user_limit**: If a voice channel, sets the maximum amount of users to be allowed at a time
     - **permission_overwrites**: Array of overwrite objects to give this channel

     - parameter guildId: Guild to create channel for
     - parameter options: Preconfigured options to give the channel on create
     */
    public func createChannel(
        for guildId: Snowflake,
        with options: [String: Any]
    ) async throws -> GuildChannel? {
        let rawData = try await self.request(.createGuildChannel(guildId), body: options)

        let data = rawData as! [String: Any]

        switch data["type"] as! Int {
        case 0:
            return GuildText(self, data)

        case 2:
            return GuildVoice(self, data)

        case 4:
            return GuildCategory(self, data)
        default: break
        }

        return nil
    }

    /**
     Creates a guild

     - parameter options: Refer to [discord docs](https://discord.com/developers/docs/resources/guild#create-guild) for guild options
     */
    public func createGuild(
        with options: [String: Any],
        then completion: ((Guild?, RequestError?) -> Void)? = nil
    ) async throws -> Guild {
        let data = try await self.request(.createGuild, body: options)

        return Guild(self, data as! [String: Any])
    }

    /**
     Creates an integration for a guild

     #### Option Params ####

     - **type**: The type of integration to create
     - **id**: The id of the user's integration to link to this guild

     - parameter guildId: Guild to create integration for
     - parameter options: Preconfigured options for this integration
     */
    public func createIntegration(
        for guildId: Snowflake,
        with options: [String: String]
    ) async throws {
        _ = try await self.request(.createGuildIntegration(guildId), body: options)
    }

    /**
     Creates an invite for channel

     #### Options Params ####

     - **max_age**: Duration in seconds before the invite expires, or 0 for never. Default 86400 (24 hours)
     - **max_uses**: Max number of people who can use this invite, or 0 for unlimited. Default 0
     - **temporary**: Whether or not this invite gives you temporary access to the guild. Default false
     - **unique**: Whether or not this invite has a unique invite code. Default false

     - parameter channelId: Channel to create invite for
     - parameter options: Options to give invite
     */
    public func createInvite(
        for channelId: Snowflake,
        with options: [String: Any] = [:]
    ) async throws -> [String: Any] {
        let data = try await self.request(.createChannelInvite(channelId), body: options)
        return data as! [String: Any]
    }

    /**
     Creates a guild role

     #### Option Params ####

     - **name**: The name of the role
     - **permissions**: The bitwise number to set role with
     - **color**: Integer value of RGB color
     - **hoist**: Whether or not this role is hoisted on the member list
     - **mentionable**: Whether or not this role is mentionable in chat

     - parameter guildId: Guild to create role for
     - parameter options: Preset options to configure role with
     */
    public func createRole(
        for guildId: Snowflake,
        with options: [String: Any]
    ) async throws -> Role {
        let data = try await self.request(.createGuildRole(guildId), body: options)
        return Role(data as! [String: Any])
    }

    /**
     Creates a webhook for a channel

     #### Options Params ####

     - **name**: The name of the webhook
     - **avatar**: The avatar string to assign this webhook in base64

     - parameter channelId: Guild channel to create webhook for
     - parameter options: Preconfigured options to create this webhook with
     */
    public func createWebhook(
        for channelId: Snowflake,
        with options: [String: String] = [:]
    ) async throws -> Webhook {
        let data = try await self.request(.createWebhook(channelId), body: options)
        return Webhook(self, data as! [String: Any])
    }

    /**
     Deletes a channel

     - parameter channelId: Channel to delete
     */
    public func deleteChannel(
        _ channelId: Snowflake
    ) async throws -> Channel? {
        let data = try await self.request(.deleteChannel(channelId))
        let channelData = data as! [String: Any]

        switch channelData["type"] as! Int {
        case 0:
            return GuildText(self, channelData)

        case 1:
            return DM(self, channelData)

        case 2:
            return GuildVoice(self, channelData)

        case 3:
            return GroupDM(self, channelData)

        case 4:
            return GuildCategory(self, channelData)

        default: break
        }

        return nil
    }

    /**
     Deletes a guild

     - parameter guildId: Guild to delete
     */
    public func deleteGuild(
        _ guildId: Snowflake
    ) async throws -> Guild {
        let data = try await self.request(.deleteGuild(guildId))
        return Guild(self, data as! [String: Any])
    }

    /**
     Deletes an emoji in a guild

     - parameter guildId: ID of the guild the emoji is in
     - parameter emojiId: ID of the emoji you would like to delete
     */
    public func deleteGuildEmoji(
        _ guildId: Snowflake,
        emojiId: Snowflake,
        reason: String
    ) async throws {
        _ = try await self.request(.deleteGuildEmoji(guildId, emojiId), reason: reason)
    }

    /**
     Deletes an integration from a guild

     - parameter integrationId: Integration to delete
     - parameter guildId: Guild to delete integration from
     */
    public func deleteIntegration(
        _ integrationId: Snowflake,
        from guildId: Snowflake
    ) async throws {
        _ = try await self.request(.deleteGuildIntegration(guildId, integrationId))
    }

    /**
     Deletes an invite

     - parameter inviteId: Invite to delete
     */
    public func deleteInvite(
        _ inviteId: String
    ) async throws -> Invite {
        let data = try await self.request(.deleteInvite(invite: inviteId))
        return Invite(self, data as! [String: Any])
    }

    /**
     Deletes a message from a channel

     - parameter messageId: Message to delete
     */
    public func deleteMessage(
        _ messageId: Snowflake,
        from channelId: Snowflake
    ) async throws {
        _ = try await self.request(.deleteMessage(channelId, messageId))
    }

    /**
     Bulk deletes messages

     - parameter messages: Array of message ids to delete
     */
    public func deleteMessages(
        _ messages: [Snowflake],
        from channelId: Snowflake
    ) async throws {
        let oldestMessage = Snowflake.fakeSnowflake(
            date: Date(timeIntervalSinceNow: -14 * 24 * 60 * 60)
        ) ?? 0

        for message in messages {
            if message < oldestMessage {
                throw ResponseError.nonSuccessfulRequest(RequestError("One of the messages you wanted to delete was older than allowed."))
            }
        }

        _ = try await self.request(.bulkDeleteMessages(channelId), body: ["messages": messages.map { $0.description }]
        )
    }

    /**
     Deletes an overwrite permission for a channel

     - parameter channelId: Channel to delete permissions from
     - parameter overwriteId: Overwrite ID to use for permissons
     */
    public func deletePermission(
        from channelId: Snowflake,
        with overwriteId: Snowflake
    ) async throws {
        _ = try await self.request(.deleteChannelPermission(channelId, overwriteId))
    }

    /**
     Deletes a reaction from a message by user

     - parameter reaction: Unicode or custom emoji to delete
     - parameter messageId: Message to delete reaction from
     - parameter userId: If nil, deletes bot's reaction from, else delete a reaction from user
     - parameter channelId: Channel to delete reaction from
     */
    public func deleteReaction(
        _ reaction: String,
        from messageId: Snowflake,
        by userId: Snowflake? = nil,
        in channelId: Snowflake
    ) async throws {
        let reaction = reaction.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        )!
        let url: Endpoint
        if let userId = userId {
            url = .deleteUserReaction(channelId, messageId, reaction, userId)
        } else {
            url = .deleteOwnReaction(channelId, messageId, reaction)
        }

        _ = try await self.request(url)
    }

    /**
     Deletes all reactions from a message

     - parameter messageId: Message to delete all reactions from
     - parameter channelId: Channel to remove reactions in
     */
    public func deleteReactions(
        from messageId: Snowflake,
        in channelId: Snowflake
    ) async throws {
        _ = try await self.request(.deleteAllReactions(channelId, messageId))
    }

    /**
     Deletes a role from this guild

     - parameter roleId: Role to delete
     - parameter guildId: Guild to delete role from
     */
    public func deleteRole(
        _ roleId: Snowflake,
        from guildId: Snowflake
    ) async throws -> Role {
        let data = try await self.request(.deleteGuildRole(guildId, roleId))
        return Role(data as! [String: Any])
    }

    /**
     Deletes a webhook

     - parameter webhookId: Webhook to delete
     */
    public func deleteWebhook(
        _ webhookId: Snowflake,
        token: String? = nil
    ) async throws {
        _ = try await self.request(.deleteWebhook(webhookId, token))
    }

    /// Disconnects the bot from the gateway
    public func disconnect() {
        self.shardManager.disconnect()
    }

    /**
     Edits a message's content

     - parameter messageId: Message to edit
     - parameter options: Dictionary c
     - parameter channelId: Channel to edit message in
     */
    public func editMessage(
        _ messageId: Snowflake,
        with options: [String: Any],
        in channelId: Snowflake
    ) async throws -> Message {
        let data = try await self.request(.editMessage(channelId, messageId), body: options)
        return Message(self, data as! [String: Any])
    }

    /**
     Edits a channel's overwrite permission

     #### Option Params ####

     - **allow**: The bitwise allowed permissions
     - **deny**: The bitwise denied permissions
     - **type**: 'member' for a user, or 'role' for a role

     - parameter permissions: ["allow": perm#, "deny": perm#, "type": "role" || "member"]
     - parameter channelId: Channel to edit permissions for
     - parameter overwriteId: Overwrite ID to use for permissions
     */
    public func editPermissions(
        _ permissions: [String: Any],
        for channelId: Snowflake,
        with overwriteId: Snowflake
    ) async throws {
        _ = try await self.request(.editChannelPermissions(channelId, overwriteId), body: permissions)
    }

    /**
     Edits bot status
     - parameter status: Status to set bot to. Either "online" (default), "idle", "dnd", "invisible"
     - parameter activity: Activities struct with activity data
     */
    public func editStatus(status: Status, activity: Activities) {

        let data: [String: Any] = [
            "since": status == .idle ? Date().milliseconds : 0,
            "status": status.rawValue,
            "activities": [["name": activity.name, "type": activity.type ]],
            "afk": status == .idle
        ]

        guard self.shardManager.shards.count > 0 else {
            self.presence = data
            return
        }

        let payload = Payload(op: .statusUpdate, data: data).encode()

        for shard in self.shardManager.shards {
            shard.send(payload, presence: true)
        }
    }

    /**
     Executes a slack style webhook

     #### Content Params ####

     Refer to the [slack documentation](https://api.slack.com/incoming-webhooks) for their webhook structure

     - parameter webhookId: Webhook to execute
     - parameter webhookToken: Token for auth to execute
     - parameter content: The slack webhook content to send
     */
    public func executeSlackWebhook(
        _ webhookId: Snowflake,
        token webhookToken: String,
        with content: [String: Any]
    ) async throws {
        _ = try await self.request(.executeSlackWebhook(webhookId, webhookToken), body: content)
    }

    /**
     Executes a webhook

     #### Content Params ####

     - **content**: Message to send
     - **username**: The username the webhook will send with the message
     - **avatar_url**: The url of the user the webhook will send
     - **tts**: Whether or not this message is tts
     - **file**: The url of the image to send
     - **embeds**: Array of embed objects to send. Refer to [Embed structure](https://discord.com/developers/docs/resources/channel#embed-object)

     - parameter webhookId: Webhook to execute
     - parameter webhookToken: Token for auth to execute
     - parameter content: String or dictionary containing message content
     */
    public func executeWebhook(
        _ webhookId: Snowflake,
        token webhookToken: String,
        with content: Any
    ) async throws {
        guard var message = content as? [String: Any] else {
            _ = try await self.request( .executeWebhook(webhookId, webhookToken), body: ["content": content])
            return
        }

        var file: String?

        if let messageFile = message["file"] {
            file = messageFile as? String
            message.removeValue(forKey: "file")
        }

        _ = try await self.request(.executeWebhook(webhookId, webhookToken), body: message, file: file)
    }

    /**
     Get's a guild's audit logs

     #### Options Params ####

     - **user_id**: String of user to look for logs of
     - **action_type**: Integer of Audit Log Event. Refer to [Audit Log Events](https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-audit-log-events)
     - **before**: String of entry id to look before
     - **limit**: Integer of how many entries to return (default 50, minimum 1, maximum 100)

     - parameter guildId: Guild to get audit logs from
     - parameter options: Optional flags to request for when getting audit logs
     */
    public func getAuditLog(
        from guildId: Snowflake,
        with options: [String: Any]? = nil
    ) async throws -> AuditLog {
        let data = try await self.request(.getGuildAuditLogs(guildId), params: options)
        return AuditLog(self, data as! [String: [Any]])
    }

    /**
     Gets a guild's bans

     - parameter guildId: Guild to get bans from
     */
    public func getBans(
        from guildId: Snowflake
    ) async throws -> [User] {
        let data = try await self.request(.getGuildBans(guildId))

        var returnUsers: [User] = []
        let users = data as! [[String: Any]]
        for user in users {
            returnUsers.append(User(self, user))
        }

        return returnUsers
    }

    /**
     Get's a basic Channel from a ChannelID (NOTE: This tries to get a channel from cache)

     - parameter channelId: The ChannelID used to get the Channel
     */
    public func getChannel(for channelId: Snowflake) -> Channel? {
        if let guild = self.getGuild(for: channelId) {
            return guild.channels[channelId]
        }

        if let dm = self.getDM(for: channelId) {
            return dm
        }

        return self.groups[channelId]
    }

    /**
     Either get a cached channel or restfully get a channel

     - parameter channelId: Channel to get
     */
    public func getChannel(
        _ channelId: Snowflake,
        rest: Bool = false
    ) async throws -> Channel? {
        guard rest else {
            guard let channel = self.getChannel(for: channelId) else {
                throw RequestError("Could not get channel locally")
            }

            return channel
        }

        let data = try await self.request(.getChannel(channelId))

        let channelData = data as! [String: Any]
        switch channelData["type"] as! Int {
        case 0:
            return GuildText(self, channelData)

        case 1:
            return DM(self, channelData)

        case 2:
            return GuildVoice(self, channelData)

        case 3:
            return GroupDM(self, channelData)

        case 4:
            return GuildCategory(self, channelData)

        default: break
        }

        return nil
    }

    /**
     Gets a channel's invites

     - parameter channelId: Channel to get invites from
     */
    public func getChannelInvites(
        from channelId: Snowflake
    ) async throws -> [[String: Any]]? {
        let data = try await self.request(.getChannelInvites(channelId))
        return data as? [[String: Any]]
    }

    /**
     Either get cached channels from guild

     - parameter guildId: Guild to get channels from
     */
    public func getChannels(
        from guildId: Snowflake,
        rest: Bool = false
    ) async throws -> [GuildChannel] {
        guard rest else {
            guard let guild = self.guilds[guildId] else {
                throw ResponseError.other(RequestError("Could not get guild locally"))
            }

            return Array(guild.channels.values)
        }

        let data = try await self.request(.getGuildChannels(guildId))

        var returnChannels = [GuildChannel]()
        let channels = data as! [[String: Any]]
        for channel in channels {
            switch channel["type"] as! Int {
            case 0:
                returnChannels.append(GuildText(self, channel))
            case 2:
                returnChannels.append(GuildVoice(self, channel))
            case 4:
                returnChannels.append(GuildCategory(self, channel))
            default: break
            }
        }

        return returnChannels
    }

    /// Gets the current user's connections
    public func getConnections(
    ) async throws -> [[String: Any]]? {
        let data = try await self.request(.getUserConnections)
        return data as? [[String: Any]]
    }

    /**
     Function to get dm from channelId (NOTE: This tries to get a DM from cache)

     - parameter channelId: Channel to get dm from
     */
    public func getDM(for channelId: Snowflake) -> DM? {
        let dms = self.dms.filter {
            $0.1.id == channelId
        }

        if dms.isEmpty { return nil }

        return dms.first?.value
    }

    /**
     Gets a DM for a user

     - parameter userId: User to get DM for
     */
    public func getDM(
        for userId: Snowflake
    ) async throws -> DM? {
        guard self.dms[userId] == nil else {
            return self.dms[userId]
        }

        let data = try await self.request(.createDM, body: ["recipient_id": userId.description])

        let dm = DM(self, data as! [String: Any])
        self.dms[userId] = dm
        return dm
    }

    /// Gets the gateway URL to connect to
    public func getGateway() async throws -> [String: Any] {
        let data = try await self.request(.gateway)
        return data as! [String: Any]
    }

    /**
     Function to get guild from channelId

     - parameter channelId: Channel to get guild from
     */
    public func getGuild(for channelId: Snowflake) -> Guild? {
        let guilds = self.guilds.filter {
            $0.1.channels[channelId] != nil
        }

        if guilds.isEmpty { return nil }

        return guilds.first?.value
    }

    /**
     Either get a cached guild or restfully get a guild

     - parameter guildId: Guild to get
     - parameter rest: Whether or not to get this guild restfully or not
     */
    public func getGuild(
        _ guildId: Snowflake,
        rest: Bool = false
    ) async throws -> Guild {
        guard rest else {
            guard let guild = self.guilds[guildId] else {
                throw ResponseError.other(RequestError("Could not get guild locally"))
            }

            return guild
        }

        let data = try await self.request(.getGuild(guildId))
        return Guild(self, data as! [String: Any])
    }

    /**
     Gets a guild's embed

     - parameter guildId: Guild to get embed from
     */
    public func getGuildEmbed(
        from guildId: Snowflake
    ) async throws -> [String: Any]? {
        let data = try await self.request(.getGuildEmbed(guildId))
        return data as? [String: Any]
    }

    public func getGuildEmoji(
        from guildId: Snowflake,
        with emojiId: Snowflake
    ) async throws -> Emoji {
        let data = try await self.request(.getGuildEmoji(guildId, emojiId))
        return Emoji(data as! [String: Any])
    }

    public func getGuildEmojis(
        from guildId: Snowflake
    ) async throws -> [Emoji] {
        let data = try await self.request(.getGuildEmojis(guildId))

        var emojis: [Emoji] = []

        for emoji in data as! [[String: Any]] {
            let emojiStruct = Emoji(emoji)
            emojis.append(emojiStruct)
        }

        return emojis
    }

    /**
     Gets a guild's invites

     - parameter guildId: Guild to get invites from
     */
    public func getGuildInvites(
        from guildId: Snowflake
    ) async throws -> [[String: Any]]? {
        let data = try await self.request(.getGuildInvites(guildId))
        return data as? [[String: Any]]
    }

    /// Gets a sticker from a guild
    public func getGuildSticker(
        from guildId: Snowflake,
        stickerId: Snowflake
    ) async throws -> Sticker {
        let data = try await self.request(.getGuildSticker(guildId, stickerId))
        return Sticker(data as! [String: Any])
    }

    /// Gets all the stickers from a guild
    public func getGuildStickers(
        from guildId: Snowflake
    ) async throws -> [Sticker] {
        let data = try await self.request(.getGuildStickers(guildId))

        var returnStickers = [Sticker]()
        let stickers = data as! [[String: Any]]
        for sticker in stickers {
            returnStickers.append(Sticker(sticker))
        }

        return returnStickers
    }

    /**
     Gets a guild's webhooks

     - parameter guildId: Guild to get webhooks from
     */
    public func getGuildWebhooks(
        from guildId: Snowflake
    ) async throws -> [Webhook] {
        let data = try await self.request(.getGuildWebhooks(guildId))

        var returnWebhooks = [Webhook]()
        let webhooks = data as! [[String: Any]]
        for webhook in webhooks {
            returnWebhooks.append(Webhook(self, webhook))
        }

        return returnWebhooks
    }

    /**
     Gets a guild's integrations

     - parameter guildId: Guild to get integrations from
     */
    public func getIntegrations(
        from guildId: Snowflake
    ) async throws -> [[String: Any]]? {
        let data = try await self.request(.getGuildIntegrations(guildId))
        return data as? [[String: Any]]
    }

    /**
     Gets an invite

     - parameter inviteId: Invite to get
     */
    public func getInvite(
        _ inviteId: String
    ) async throws -> [String: Any]? {
        let data = try await self.request(.getInvite(inviteId))
        return data as? [String: Any]
    }

    /**
     Gets a member from guild

     - parameter userId: Member to get
     - parameter guildId: Guild to get member from
     */
    public func getMember(
        _ userId: Snowflake,
        from guildId: Snowflake
    ) async throws -> Member {
        let data = try await self.request(.getGuildMember(guildId, userId))
        return Member(self, self.guilds[guildId]!, data as! [String: Any])
    }

    /**
     Gets an array of guild members in a guild

     #### Option Params ####

     - **limit**: Amount of members to get (1-1000)
     - **after**: Message Id of highest member to get members from

     - parameter guildId: Guild to get members from
     - parameter options: Dictionary containing optional optiond regarding what members are returned
     */
    public func getMembers(
        from guildId: Snowflake,
        with options: [String: Any]? = nil
    ) async throws -> [Member] {
        let data = try await self.request(.listGuildMembers(guildId), params: options)

        var returnMembers = [Member]()
        let members = data as! [[String: Any]]
        for member in members {
            returnMembers.append(Member(self, self.guilds[guildId]!, member))
        }

        return returnMembers
    }

    /**
     Gets a message from channel

     - parameter messageId: Message to get
     - parameter channelId: Channel to get message from
     */
    public func getMessage(
        _ messageId: Snowflake,
        from channelId: Snowflake
    ) async throws -> Message {
        let data = try await self.request(.getChannelMessage(channelId, messageId))
        return Message(self, data as! [String: Any])
    }

    /**
     Gets an array of messages from channel

     #### Option Params ####

     - **around**: Message Id to get messages around
     - **before**: Message Id to get messages before this one
     - **after**: Message Id to get messages after this one
     - **limit**: Number of how many messages you want to get (1-100)

     - parameter channelId: Channel to get messages from
     - parameter options: Dictionary containing optional options regarding how many messages, or when to get them
     */
    public func getMessages(
        from channelId: Snowflake,
        with options: [String: Any]? = nil
    ) async throws -> [Message] {
        let data = try await self.request(.getChannelMessages(channelId), params: options)

        var returnMessages = [Message]()
        let messages = data as! [[String: Any]]
        for message in messages {
            returnMessages.append(Message(self, message))
        }

        return returnMessages
    }

    /**
     Get pinned messages from a channel

     - parameter channelId: Channel to get pinned messages fromn
     */
    public func getPinnedMessages(
        from channelId: Snowflake
    ) async throws -> [Message] {
        let data = try await self.request(.getPinnedMessages(channelId))

        var returnMessages = [Message]()
        let messages = data as! [[String: Any]]
        for message in messages {
            returnMessages.append(Message(self, message))
        }

        return returnMessages
    }

    /**
     Gets number of users who would be pruned by x amount of days in a guild

     - parameter guildId: Guild to get prune count for
     - parameter limit: Number of days to get prune count for
     */
    public func getPruneCount(
        from guildId: Snowflake,
        for limit: Int
    ) async throws -> Int? {
        let data = try await self.request(.getGuildPruneCount(guildId), params: ["days": limit])
        return (data as! [String: Int])["pruned"]
    }

    /**
     Gets an array of users who used reaction from message

     - parameter reaction: Unicode or custom emoji to get
     - parameter messageId: Message to get reaction users from
     - parameter channelId: Channel to get reaction from
     */
    public func getReaction(
        _ reaction: String,
        from messageId: Snowflake,
        in channelId: Snowflake
    ) async throws -> [User] {
        let data = try await self.request(.getReactions(channelId, messageId, reaction.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!))

        var returnUsers = [User]()
        let users = data as! [[String: Any]]
        for user in users {
            returnUsers.append(User(self, user))
        }

        return returnUsers
    }

    /**
     Gets a guild's roles

     - parameter guildId: Guild to get roles from
     */
    public func getRoles(
        from guildId: Snowflake
    ) async throws -> [Role] {
        let data = try await self.request(.getGuildRoles(guildId))

        var returnRoles = [Role]()
        let roles = data as! [[String: Any]]
        for role in roles {
            returnRoles.append(Role(role))
        }

        return returnRoles
    }

    /**
     Gets shard that is handling a guild

     - parameter guildId: Guild to get shard for
     */
    public func getShard(for guildId: Snowflake) -> Int {
        return Int((guildId.rawValue >> 22) % UInt64(self.shardCount))
    }

    /// Gets a sticker
    public func getSticker(
        stickerId: Snowflake
    ) async throws -> Sticker {
        let data = try await self.request(.getSticker(stickerId))
        return Sticker(data as! [String: Any])
    }

    /**
     Either get a cached user or restfully get a user

     - parameter userId: User to get
     */
    public func getUser(
        _ userId: Snowflake
    ) async throws -> User {
        let data = try await self.request(.getUser(userId))
        return User(self, data as! [String: Any])
    }

    /**
     Get's the current user's guilds

     #### Option Params ####

     - **before**: Guild Id to get guilds before this one
     - **after**: Guild Id to get guilds after this one
     - **limit**: Amount of guilds to return (1-100)

     - parameter options: Dictionary containing options regarding what kind of guilds are returned, and amount
     */
    public func getUserGuilds(
        with options: [String: Any]? = nil
    ) async throws -> [UserGuild] {
        let data = try await self.request(.getCurrentUserGuilds, params: options)

        var returnGuilds = [UserGuild]()
        let guilds = data as! [[String: Any]]
        for guild in guilds {
            returnGuilds.append(UserGuild(guild))
        }

        return returnGuilds
    }

    /**
     Gets an array of voice regions from a guild

     - parameter guildId: Guild to get voice regions from
     */
    public func getVoiceRegions(
        from guildId: Snowflake
    ) async throws -> [[String: Any]]? {
        let data = try await self.request(.getGuildVoiceRegions(guildId))
        return data as? [[String: Any]]
    }

    /**
     Gets a webhook

     - parameter webhookId: Webhook to get
     */
    public func getWebhook(
        _ webhookId: Snowflake,
        token: String? = nil
    ) async throws -> Webhook {
        let data = try await self.request(.getWebhook(webhookId, token))
        return Webhook(self, data as! [String: Any])
    }

    /**
     Gets a channel's webhooks

     - parameter channelId: Channel to get webhooks from
     */
    public func getWebhooks(
        from channelId: Snowflake
    ) async throws -> [Webhook] {
        let data = try await self.request(.getChannelWebhooks(channelId))

        var returnWebhooks = [Webhook]()
        let webhooks = data as! [[String: Any]]
        for webhook in webhooks {
            returnWebhooks.append(Webhook(self, webhook))
        }

        return returnWebhooks
    }

    /**
     Kicks a member from a guild

     - parameter userId: Member to kick from server
     - parameter guildId: Guild to remove them from
     - parameter reason: Reason why member was kicked from guild (attached to audit log)
     */
    public func kick(
        _ userId: Snowflake,
        from guildId: Snowflake,
        for reason: String? = nil
    ) async throws {
        _ = try await self.request(.removeGuildMember(guildId, userId), reason: reason)
    }

    /**
     Kills a shard

     - parameter id: Id of shard to kill
     */
    public func kill(_ id: Int) {
        self.shardManager.kill(id)
    }

    /**
     Leaves a guild

     - parameter guildId: Guild to leave
     */
    public func leaveGuild(
        _ guildId: Snowflake
    ) async throws {
        _ = try await self.request(.leaveGuild(guildId))
    }

    /**
     Modifies a guild channel

     #### Options Params ####

     - **name**: Name to give channel
     - **position**: Channel position to set it to
     - **topic**: If a text channel, sets the topic of the text channel
     - **bitrate**: If a voice channel, sets the bitrate for the voice channel
     - **user_limit**: If a voice channel, sets the maximum allowed users in a voice channel

     - parameter channelId: Channel to edit
     - parameter options: Optons to give channel
     */
    public func modifyChannel(
        _ channelId: Snowflake,
        with options: [String: Any] = [:]
    ) async throws -> GuildChannel? {
        let data = try await self.request(.modifyChannel(channelId), body: options)

        let channelData = data as! [String: Any]

        switch channelData["type"] as! Int {
        case 0:
            return GuildText(self, channelData)
        case 2:
            return GuildVoice(self, channelData)
        case 4:
            return GuildCategory(self, channelData)
        default: break
        }

        return nil
    }

    /**
     Modifies channel positions from a guild

     #### Options Params ####

     Array of the following:

     - **id**: The channel id to modify
     - **position**: The sorting position of the channel

     - parameter guildId: Guild to modify channel positions from
     - parameter options: Preconfigured options to set channel positions to
     */
    public func modifyChannelPositions(
        for guildId: Snowflake,
        with options: [[String: Any]]
    ) async throws -> [GuildChannel] {
        let data = try await self.request(.modifyGuildChannelPositions(guildId), body: ["array": options])

        var returnChannels = [GuildChannel]()
        let channels = data as! [[String: Any]]
        for channel in channels {
            switch channel["type"] as! Int {
            case 0:
                returnChannels.append(GuildText(self, channel))
            case 2:
                returnChannels.append(GuildVoice(self, channel))
            case 4:
                returnChannels.append(GuildCategory(self, channel))
            default: break
            }
        }

        return returnChannels
    }

    /**
     Modifes a Guild Embed

     #### Options Params ####

     - **enabled**: Whether or not embed should be enabled
     - **channel_id**: Snowflake of embed channel

     - parameter guildId: Guild to edit embed in
     - parameter options: Dictionary of options to give embed
     */
    public func modifyEmbed(
        for guildId: Snowflake,
        with options: [String: Any]
    ) async throws -> [String: Any]? {
        let data = try await self.request(.modifyGuildEmbed(guildId), body: options)
        return data as? [String: Any]
    }

    /**
     Modifes an emoji in a guild

     #### Options Params ####

     - **name**: New name of the emoji
     - **roles**: Array of role `Snowflake` that you want to limit the emoji too

     - parameter options: Dictionary of options to give embed
     */
    public func modifyEmoji(
        for guildId: Snowflake,
        emojiId: Snowflake,
        with options: [String: Any],
        reason: String
    ) async throws -> Emoji {
        let data = try await self.request(.modifyGuildEmoji(guildId, emojiId), body: options, reason: reason)
        return Emoji(data as! [String: Any])
    }

    /**
     Modifies a guild

     #### Options Params ####

     - **name**: The name to assign to the guild
     - **region**: The region to set this guild to
     - **verification_level**: The guild verification level integer
     - **default_message_notifications**: The guild default message notification settings integer
     - **afk_channel_id**: The channel id to assign afks
     - **afk_timeout**: The amount of time in seconds to afk a user in voice
     - **icon**: The icon in base64 string
     - **owner_id**: The user id to make own of this server
     - **splash**: If a VIP server, the splash image in base64 to assign

     - parameter guildId: Guild to modify
     - parameter options: Preconfigured options to modify guild with
     */
    public func modifyGuild(
        _ guildId: Snowflake,
        with options: [String: Any]
    ) async throws -> Guild {
        let data = try await self.request(.modifyGuild(guildId), body: options)
        return Guild(self, data as! [String: Any], self.getShard(for: guildId))
    }

    /**
     Modifies an integration from a guild

     #### Option Params ####

     - **expire_behavior**: The behavior when an integration subscription lapses (see the [integration](https://discord.com/developers/docs/resources/guild#integration-object) object documentation)
     - **expire_grace_period**: Period (in seconds) where the integration will ignore lapsed subscriptions
     - **enable_emoticons**: Whether emoticons should be synced for this integration (twitch only currently), true or false

     - parameter integrationId: Integration to modify
     - parameter guildId: Guild to modify integration from
     - parameter options: Preconfigured options to modify this integration with
     */
    public func modifyIntegration(
        _ integrationId: Snowflake,
        for guildId: Snowflake,
        with options: [String: Any]
    ) async throws {
        _ = try await self.request(.modifyGuildIntegration(guildId, integrationId), body: options)
    }

    /**
     Modifies a member from a guild

     #### Options Params ####

     - **nick**: The nickname to assign
     - **roles**: Array of role id's that should be assigned to the member
     - **mute**: Whether or not to server mute the member
     - **deaf**: Whether or not to server deafen the member
     - **channel_id**: If the user is connected to a voice channel, assigns them the new voice channel they are to connect.

     - parameter userId: Member to modify
     - parameter guildId: Guild to modify member in
     - parameter options: Preconfigured options to modify member with
     */
    public func modifyMember(
        _ userId: Snowflake,
        in guildId: Snowflake,
        with options: [String: Any],
        for reason: String? = nil
    ) async throws {
        _ = try await self.request(.modifyGuildMember(guildId, userId), body: options, reason: reason)
    }

    /**
     Modifies a role from a guild

     #### Options Params ####

     - **name**: The name to assign to the role
     - **permissions**: The bitwise permission integer
     - **color**: RGB int color value to assign to the role
     - **hoist**: Whether or not this role should be hoisted on the member list
     - **mentionable**: Whether or not this role should be mentionable by everyone

     - parameter roleId: Role to modify
     - parameter guildId: Guild to modify role from
     - parameter options: Preconfigured options to modify guild roles with
     */
    public func modifyRole(
        _ roleId: Snowflake,
        for guildId: Snowflake,
        with options: [String: Any]
    ) async throws -> Role {
        let data = try await self.request(.modifyGuildRole(guildId, roleId), body: options)
        return Role(data as! [String: Any])
    }

    /**
     Modifies role positions from a guild

     #### Options Params ####

     Array of the following:

     - **id**: The role id to edit position
     - **position**: The sorting position of the role

     - parameter guildId: Guild to modify role positions from
     - parameter options: Preconfigured options to set role positions to
     */
    public func modifyRolePositions(
        for guildId: Snowflake,
        with options: [[String: Any]]
    ) async throws -> [Role] {
        let data = try await self.request(.modifyGuildRolePositions(guildId), body: ["array": options])

        var returnRoles: [Role] = []
        let roles = data as! [[String: Any]]
        for role in roles {
            returnRoles.append(Role(role))
        }

        return returnRoles
    }

    /**
     Modifies a webhook

     #### Option Params ####

     - **name**: The name given to the webhook
     - **avatar**: The avatar image to give webhook in base 64 string

     - parameter webhookId: Webhook to modify
     - parameter options: Preconfigured options to modify webhook with
     */
    public func modifyWebhook(
        _ webhookId: Snowflake,
        token: String? = nil,
        with options: [String: String]
    ) async throws -> Webhook {
        let data = try await self.request(.modifyWebhook(webhookId, token), body: options)
        return Webhook(self, data as! [String: Any])
    }

    /**
     Moves a member in a voice channel to another voice channel (if they are in one)

     - parameter userId: User to move
     - parameter guildId: Guild that they're in currently
     - parameter channelId: The Id of the channel to send them to
     */
    public func moveMember(
        _ userId: Snowflake,
        in guildId: Snowflake,
        to channelId: Snowflake
    ) async throws {
        _ = try await self.request(.modifyGuildMember(guildId, userId), body: ["channel_id": channelId.description])
    }

    /**
     Pins a message to a channel

     - parameter messageId: Message to pin
     - parameter channelId: Channel to pin message in
     */
    public func pin(
        _ messageId: Snowflake,
        in channelId: Snowflake
    ) async throws {
        _ = try await self.request(.addPinnedChannelMessage(channelId, messageId))
    }

    /**
     Prunes members for x amount of days in a guild

     - parameter guildId: Guild to prune members in
     - parameter limit: Amount of days for prunned users
     */
    public func pruneMembers(
        in guildId: Snowflake,
        for limit: Int
    ) async throws -> Int? {
        guard limit > 1 else {
            throw ResponseError.other(RequestError("Limit you provided was lower than 1 user."))
        }

        let data = try await self.request(.beginGuildPrune(guildId), params: ["days": limit])
        return (data as! [String: Int])["pruned"]
    }

    /**
     Removes a user from a Group DM

     - parameter userId: User to remove from DM
     - parameter groupDMId: Snowflake of Group DM you want to remove user from
     */
    public func removeUser(
        _ userId: Snowflake,
        fromGroupDM groupDMId: Snowflake
    ) async throws {
        _ = try await self.request(.groupDMRemoveRecipient(groupDMId, userId))
    }

    public func send(
        _ content: String,
        to channelId: Snowflake
    ) async throws -> Message? {
        let data = try await self.request(.createMessage(channelId), body: ["content": content])

        return Message(self, data as! [String: Any])
    }

    /**
     Sends a message to channel

     - parameter content: String containing message
     - parameter channelId: Channel to send message to
     */
    public func send(
        _ content: String,
        to channelId: Snowflake
    ) async throws -> Message {
        let data = try await self.request(.createMessage(channelId), body: ["content": content])
        return Message(self, data as! [String: Any])
    }

    /**
     Sends a message to channel

     #### Content Dictionary Params ####

     - **content**: Message to send
     - **username**: The username the webhook will send with the message
     - **avatar_url**: The url of the user the webhook will send
     - **tts**: Whether or not this message is tts
     - **file**: The url of the image to send
     - **embed**: The embed object to send. Refer to [Embed structure](https://discord.com/developers/docs/resources/channel#embed-object)

     - parameter content: Dictionary containing info on message
     - parameter channelId: Channel to send message to
     */
    public func send(
        _ content: [String: Any],
        to channelId: Snowflake
    ) async throws -> Message {
        var content = content
        var file: String?

        if let messageFile = content["file"] as? String {
            file = messageFile
            content.removeValue(forKey: "file")
        }

        let data = try await self.request(.createMessage(channelId), body: !content.isEmpty ? content : nil, file: file)
        return Message(self, data as! [String: Any])
    }

    /**
     Sends an embed to channel

     - parameter content: Embed to send as message
     - parameter channelId: Channel to send message to
     */
    public func send(
        _ embeds: EmbedBuilder...,
        to channelId: Snowflake
    ) async throws -> Message {
        let jsonData = try! self.encoder.encode(EmbedBody(embeds: embeds))

        let data = try! await self.requestWithBodyAsData(.createMessage(channelId), body: jsonData)

        return Message(self, data as! [String: Any])
    }

    /**
     Sends buttons to channel

     - parameter content: Embed to send as message
     - parameter channelId: Channel to send message to
     */
    public func send(
        _ content: ButtonBuilder,
        to channelId: Snowflake
    ) async throws -> Message {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let content = try! jsonEncoder.encode(content)

        let data = try await self.requestWithBodyAsData(.createMessage(channelId), body: content)
        return Message(self, data as! [String: Any])
    }

    /**
     Sends a Select Menu to channel

     - parameter content: Embed to send as message
     - parameter channelId: Channel to send message to
     */
    public func send(
        _ content: SelectMenuBuilder,
        to channelId: Snowflake
    ) async throws -> Message {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let content = try! jsonEncoder.encode(content)

        let data = try await self.requestWithBodyAsData(.createMessage(channelId), body: content)
        return Message(self, data as! [String: Any])
    }

    public func setIntents(intents: Intents...) {
        self.intentArray = intents
        for intent in intents {
            self.intents += intent.rawValue
        }
    }

    /**
     Sets bot to typing in channel

     - parameter channelId: Channel to set typing to
     */
    public func setTyping(
        for channelId: Snowflake
    ) async throws {
        _ = try await self.request(.triggerTypingIndicator(channelId))
    }

    /**
     Sets bot's username

     - parameter name: Name to set bot's username to
     */
    public func setUsername(
        to name: String
    ) async throws -> User {
        let data = try await self.request(.modifyCurrentUser, body: ["username": name])
        return User(self, data as! [String: Any])
    }

    /**
     Used to spawn a shard

     - parameter id: Id of shard to spawn
     */
    public func spawn(_ id: Int) {
        self.shardManager.spawn(id)
    }

    /**
     Syncs an integration for a guild

     - parameter integrationId: Integration to sync
     - parameter guildId: Guild to sync intregration for
     */
    public func syncIntegration(
        _ integrationId: Snowflake,
        for guildId: Snowflake
    ) async throws {
        _ = try await self.request(.syncGuildIntegration(guildId, integrationId))
    }

    /**
     Unbans a user from this guild

     - parameter userId: User to unban
     */
    public func unbanMember(
        _ userId: Snowflake,
        from guildId: Snowflake
    ) async throws {
        _ = try await self.request(.removeGuildBan(guildId, userId))
    }

    /**
     Unpins a pinned message from a channel

     - parameter messageId: Pinned message to unpin
     */
    public func unpin(
        _ messageId: Snowflake,
        from channelId: Snowflake
    ) async throws {
        _ = try await self.request(.deletePinnedChannelMessage(channelId, messageId))
    }

    public func uploadEmoji(
        name: String,
        emoji: Icon,
        roles: [Role],
        guildId: Snowflake
    ) async throws -> Emoji {
        let emoji = Emoji(name: name, base64Image: emoji.toDataString(), roles: roles)

        let jsonData = try! self.encoder.encode(emoji)

        let data = try await self.requestWithBodyAsData(.uploadEmoji(guildId), body: jsonData)
        return Emoji(data as! [String: Any])
    }

    public func uploadSlashCommand(
        commandData: SlashCommandBuilder
    ) async throws {
        let jsonData = try! self.encoder.encode(commandData)

        _ = try await self.requestWithBodyAsData(.uploadGlobalApplicationCommand(self.user!.id), body: jsonData)
    }

    public func uploadUserCommand(
        commandData: UserCommandBuilder
    ) async throws {
        let jsonData = try self.encoder.encode(commandData)

        _ = try await self.requestWithBodyAsData(.uploadGlobalApplicationCommand(self.user!.id), body: jsonData)
    }

    public func uploadMessageCommand(
        commandData: MessageCommandBuilder
    ) async throws {
        let jsonData = try self.encoder.encode(commandData)

        _ = try await self.requestWithBodyAsData(.uploadGlobalApplicationCommand(self.user!.id), body: jsonData)
    }

    public func deleteApplicationCommand(
        commandId: Snowflake
    ) async throws {
        _ = try await self.request(.deleteGlobalSlashCommand(self.user!.id, commandId))
    }
}
