//
//  EventHandler.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation

/// EventHandler
extension Shard {

    /**
     Handles all dispatch events

     - parameter data: Data sent with dispatch
     - parameter eventName: Event name sent with dispatch
     */
    func handleEvent(
        _ data: [String: Any],
        _ eventName: String
    ) async {

        guard let event = Event(rawValue: eventName) else {
            self.swiftcord.log("Received unknown event: \(eventName)")
            return
        }

        for listener in self.swiftcord.listenerAdaptors {
            switch event {

            /// CHANNEL_CREATE
            case .channelCreate:
                switch data["type"] as! Int {
                case 0:
                    let channel = GuildText(self.swiftcord, data)
                    await listener.onChannelCreate(event: channel)

                case 1:
                    let dm = DM(self.swiftcord, data)
                    await listener.onChannelCreate(event: dm)

                case 2:
                    let channel = GuildVoice(self.swiftcord, data)
                    await listener.onVoiceChannelCreate(event: channel)

                case 3:
                    let group = GroupDM(self.swiftcord, data)
                    await listener.onChannelCreate(event: group)

                case 4:
                    let category = GuildCategory(self.swiftcord, data)
                    await listener.onCategoryCreate(event: category)

                default: return
                }

                return

            case .channelDelete:
                let type = data["type"] as! Int
                switch type {
                case 0, 2, 4:
                    let guildId = Snowflake(data["guild_id"])!
                    guard let guild = self.swiftcord.guilds[guildId] else {
                        return
                    }

                    let channelId = Snowflake(data["id"])!
                    guard guild.channels.removeValue(forKey: channelId) != nil else {
                        return
                    }

                    // We made the case this broad so we can remove from our cache. We must now pass the proper type to the ListenerAdapter
                    if type == 0 {
                        // Text
                        await listener.onChannelDelete(event: GuildText(self.swiftcord, data))
                    } else if type == 2 {
                        // Voice
                        await listener.onVoiceChannelDelete(event: GuildVoice(self.swiftcord, data))
                    } else {
                        // Category
                        await listener.onCategoryDelete(event: GuildCategory(self.swiftcord, data))
                    }

                case 1:
                    let recipient = (data["recipients"] as! [[String: Any]])[0]
                    let userId = Snowflake(recipient["id"])!
                    guard let dm = self.swiftcord.dms.removeValue(forKey: userId) else {
                        return
                    }
                    await listener.onChannelDelete(event: dm)

                case 3:
                    let channelId = Snowflake(data["id"])!
                    guard let group = self.swiftcord.groups.removeValue(forKey: channelId) else {
                        return
                    }
                    await listener.onChannelDelete(event: group)

                default: return
                }

            /// CHANNEL_PINS_UPDATE
            case .channelPinsUpdate:
                let channelId = Snowflake(data["channel_id"])!
                let timestamp = data["last_pin_timestamp"] as? String
                guard let channel = self.swiftcord.getChannel(for: channelId) else {
                    return
                }

                await listener.onChannelPinUpdate(event: channel, lastPin: timestamp?.date)

            /// CHANNEL_UPDATE
            case .channelUpdate:
                let type = data["type"] as! Int
                switch type {
                case 0, 2, 4:
                    let guildId = Snowflake(data["guild_id"])!
                    let channelId = Snowflake(data["id"])!
                    guard let channel = self.swiftcord.guilds[guildId]!.channels[channelId] as? Updatable else {
                        return
                    }

                    channel.update(data)

                    if type == 0 {
                        // Text
                        await listener.onChannelUpdate(event: channel as! TextChannel)
                    } else if type == 2 {
                        // Voice
                        await listener.onVoiceChannelUpdate(event: channel as! GuildVoice)
                    } else {
                        // Category
                        await listener.onCategoryUpdate(event: channel as! GuildCategory)
                    }

                case 3:
                    let group = GroupDM(self.swiftcord, data)
                    self.swiftcord.groups[group.id] = group

                    await listener.onChannelUpdate(event: group)

                default: return
                }

            /// GUILD_BAN_ADD
            case .guildBanAdd:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let user = User(self.swiftcord, data["user"] as! [String: Any])
                await listener.onGuildBan(guild: guild, user: user)

            /// GUILD_BAN_REMOVE
            case .guildBanRemove:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let user = User(self.swiftcord, data["user"] as! [String: Any])
                await listener.onGuildUnban(guild: guild, user: user)

            /// GUILD_CREATE
            case .guildCreate:
                let guild = Guild(self.swiftcord, data, self.id)
                self.swiftcord.guilds[guild.id] = guild

                if self.swiftcord.unavailableGuilds[guild.id] != nil {
                    self.swiftcord.unavailableGuilds.removeValue(forKey: guild.id)
                    await listener.onGuildAvailable(guild: guild)
                } else {
                    await listener.onGuildCreate(guild: guild)
                }

                if self.swiftcord.options.willCacheAllMembers && guild.members.count != guild.memberCount {
                    self.requestOfflineMembers(for: guild.id)
                }

                await listener.onGuildReady(guild: guild)

            /// GUILD_DELETE
            case .guildDelete:
                let guildId = Snowflake(data["id"])!
                guard let guild = self.swiftcord.guilds.removeValue(forKey: guildId) else {
                    return
                }

                if data["unavailable"] != nil {
                    let unavailableGuild = UnavailableGuild(data, self.id)
                    self.swiftcord.unavailableGuilds[guild.id] = unavailableGuild
                    await listener.onUnavailableGuildDelete(guild: unavailableGuild)
                } else {
                    await listener.onGuildDelete(guild: guild)
                }

            /// GUILD_EMOJIS_UPDATE
            case .guildEmojisUpdate:
                let emojis = (data["emojis"] as! [[String: Any]]).map(Emoji.init)
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }

                guild.emojis = emojis
                await listener.onGuildEmojisUpdate(guild: guild, emojis: emojis)

            /// GUILD_INTEGRATIONS_UPDATE
            case .guildIntegrationsUpdate:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }

                await listener.onGuildIntegrationUpdate(guild: guild)

            /// GUILD_MEMBER_ADD
            case .guildMemberAdd:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let member = Member(self.swiftcord, guild, data)
                guild.members[member.user!.id] = member
                await listener.onGuildMemberJoin(guild: guild, member: member)

            /// GUILD_MEMBER_REMOVE
            case .guildMemberRemove:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let user = User(self.swiftcord, data["user"] as! [String: Any])
                guild.members.removeValue(forKey: user.id)
                await listener.onGuildMemberLeave(guild: guild, user: user)

            /// GUILD_MEMBERS_CHUNK
            case .guildMembersChunk:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let members = data["members"] as! [[String: Any]]
                for member in members {
                    let member = Member(self.swiftcord, guild, member)
                    guild.members[member.user!.id] = member
                }

            /// GUILD_MEMBER_UPDATE
            case .guildMemberUpdate:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let member = Member(self.swiftcord, guild, data)
                guild.members[member.user!.id] = member
                await listener.onGuildMemberUpdate(guild: guild, member: member)

            /// GUILD_ROLE_CREATE
            case .guildRoleCreate:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let role = Role(data["role"] as! [String: Any])
                guild.roles[role.id] = role
                await listener.onGuildRoleCreate(guild: guild, role: role)

            /// GUILD_ROLE_DELETE
            case .guildRoleDelete:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let roleId = Snowflake(data["role_id"])!
                guard let role = guild.roles[roleId] else {
                    return
                }
                guild.roles.removeValue(forKey: role.id)
                await listener.onGuildRoleDelete(guild: guild, role: role)

            /// GUILD_ROLE_UPDATE
            case .guildRoleUpdate:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let role = Role(data["role"] as! [String: Any])
                guild.roles[role.id] = role
                await listener.onGuildRoleUpdate(guild: guild, role: role)

            /// GUILD_UPDATE
            case .guildUpdate:
                let guildId = Snowflake(data["id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                guild.update(data)
                await listener.onGuildUpdate(guild: guild)

            /// MESSAGE_CREATE
            case .messageCreate:
                let msg = Message(self.swiftcord, data)

                if let channel = msg.channel as? GuildText {
                    channel.lastMessageId = msg.id
                }

                await listener.onMessageCreate(event: msg)

            /// MESSAGE_DELETE
            case .messageDelete:
                let channelId = Snowflake(data["channel_id"])!
                guard let channel = self.swiftcord.getChannel(for: channelId) else {
                    return
                }
                let messageId = Snowflake(data["id"])!
                await listener.onMessageDelete(messageId: messageId, channel: channel)

            /// MESSAGE_BULK_DELETE
            case .messageDeleteBulk:
                let channelId = Snowflake(data["channel_id"])!
                guard let channel = self.swiftcord.getChannel(for: channelId) else {
                    return
                }
                let messageIds = (data["ids"] as! [String]).map({ Snowflake($0)! })
                await listener.onMessageBulkDelete(messageIds: messageIds, channel: channel)

            /// MESSAGE_REACTION_REMOVE_ALL
            case .messageReactionRemoveAll:
                let channelId = Snowflake(data["channel_id"])!
                guard let channel = self.swiftcord.getChannel(for: channelId) else {
                    return
                }
                let messageId = Snowflake(data["message_id"])!
                await listener.onMessageReactionRemoveAll(messageId: messageId, channel: channel)

            /// MESSAGE_UPDATE
            case .messageUpdate:
                // TODO: Implement this
                break

            /// PRESENCE_UPDATE
            case .presenceUpdate:
                let userId = Snowflake((data["user"] as! [String: Any])["id"])!
                let presence = Presence(data)
                let guildID = Snowflake(data["guild_id"])!

                guard self.swiftcord.options.willCacheAllMembers else {
                    guard presence.status == .offline else { return }

                    self.swiftcord.guilds[guildID]?.members.removeValue(forKey: userId)
                    return
                }

                self.swiftcord.guilds[guildID]?.members[userId]?.presence = presence
                let member = self.swiftcord.guilds[guildID]?.members[userId]

                await listener.onPresenceUpdate(member: member, presence: presence)

            /// READY
            case .ready:
                self.swiftcord.readyTimestamp = Date()
                self.sessionId = data["session_id"] as? String

                let guilds = data["guilds"] as! [[String: Any]]

                for guild in guilds {
                    let guildID = Snowflake(guild["id"])!
                    self.swiftcord.unavailableGuilds[guildID] = UnavailableGuild(guild, self.id)
                }

                self.swiftcord.shardsReady += 1
                await listener.onShardReady(id: self.id)

                if self.swiftcord.shardsReady == self.swiftcord.shardCount {
                    self.swiftcord.user = User(self.swiftcord, data["user"] as! [String: Any])
                    await listener.onReady(botUser: self.swiftcord.user!)
                }

            /// MESSAGE_REACTION_ADD,
            case .reactionAdd:
                let channelId = Snowflake(data["channel_id"])!
                guard let channel = self.swiftcord.getChannel(for: channelId) else {
                    return
                }
                let userID = Snowflake(data["user_id"])!
                let messageID = Snowflake(data["message_id"])!
                let emoji = Emoji(data["emoji"] as! [String: Any])
                await listener.onMessageReactionAdd(channel: channel, messageId: messageID, userId: userID, emoji: emoji)

            /// MESSAGE_REACTION_REMOVE
            case .reactionRemove:
                let channelId = Snowflake(data["channel_id"])!
                guard let channel = self.swiftcord.getChannel(for: channelId) else {
                    return
                }
                let userID = Snowflake(data["user_id"])!
                let messageID = Snowflake(data["message_id"])!
                let emoji = Emoji(data["emoji"] as! [String: Any])
                await listener.onMessageReactionRemove(channel: channel, messageId: messageID, userId: userID, emoji: emoji)

            /// THREAD_CREATE
            case .threadCreate:
                let thread = ThreadChannel(swiftcord, data)
                await listener.onThreadCreate(event: thread)

            case .threadDelete:
                let thread = ThreadChannel(swiftcord, data)
                await listener.onThreadDelete(event: thread)

            case .threadUpdate:
                let thread = ThreadChannel(swiftcord, data)
                await listener.onThreadUpdate(event: thread)

            /// TYPING_START
            case .typingStart:
                #if !os(Linux)
                let timestamp = Date(timeIntervalSince1970: data["timestamp"] as! Double)
                #else
                let timestamp = Date(timeIntervalSince1970: Double(data["timestamp"] as! Int))
                #endif

                let channelId = Snowflake(data["channel_id"])!
                guard let channel = self.swiftcord.getChannel(for: channelId) else {
                    return
                }
                let userId = Snowflake(data["user_id"])!
                await listener.onTypingStart(channel: channel, userId: userId, time: timestamp)

            /// USER_UPDATE
            case .userUpdate:
                await listener.onUserUpdate(event: User(self.swiftcord, data))

            /// VOICE_STATE_UPDATE
            case .voiceStateUpdate:
                let guildId = Snowflake(data["guild_id"])!
                guard let guild = self.swiftcord.guilds[guildId] else {
                    return
                }
                let channelId = Snowflake(data["channel_id"])
                let userId = Snowflake(data["user_id"])!

                if channelId != nil {
                    let voiceState = VoiceState(data)

                    guild.voiceStates[userId] = voiceState
                    guild.members[userId]?.voiceState = voiceState

                    await listener.onVoiceChannelJoin(userId: userId, state: voiceState)
                } else {
                    guild.voiceStates.removeValue(forKey: userId)
                    guild.members[userId]?.voiceState = nil

                    await listener.onVoiceChannelLeave(userId: userId)
                }

            case .voiceServerUpdate:
                var sessionId = ""
                
                for shard in self.swiftcord.shardManager.shards where shard.id == self.swiftcord.getShard(for: Snowflake(data["guild_id"])!) {
                    sessionId = shard.sessionId!
                }
                
                do {
                    let voiceClient = try VoiceClient(
                        self.swiftcord,
                        gatewayUrl: "wss://\(data["endpoint"] as! String)",
                        token: data["token"] as! String,
                        guildId: Snowflake(data["guild_id"])!,
                        sessionId: sessionId,
                        eventLoopGroup: self.eventLoopGroup
                    )
                    
                    // Start the voice client.
                    await voiceClient.start()
                } catch {
                    self.swiftcord.error("No suitable networking interface found. Swiftcord cannot start the voice client without one.")
                }
            
                // We cannot dispatch the VoiceClient to the user quite yet.
                return
            case .audioData:
                return
            case .connectionClose:
                return
            case .disconnect:
                return
            case .guildAvailable:
                return
            case .guildUnavailable:
                return
            case .payload:
                return
            case .resume:
                return
            case .resumed:
                return
            case .shardReady:
                return
            case .voiceChannelJoin:
                return
            case .voiceChannelLeave:
                return
            case .interaction:
                // Convert basic interaction event to specified event
                let initialType = data["type"] as! Int

                let interactionDict = data["data"] as! [String: Any]
                if initialType == 2 {
                    let type = interactionDict["type"] as! Int
                    // Application Command event
                    switch type {
                    case 1:
                        await self.handleEvent(data, Event.slashCommandEvent.rawValue)
                    case 2:
                        await self.handleEvent(data, Event.userCommandEvent.rawValue)
                    case 3:
                        await self.handleEvent(data, Event.messageCommandEvent.rawValue)
                    default: return
                    }

                    return
                } else if initialType == 3 {
                    let type = interactionDict["component_type"] as! Int
                    // Message component event (Buttons/Select Boxes)
                    if type == 2 {
                        await self.handleEvent(data, Event.buttonEvent.rawValue)
                    } else if type == 3 {
                        await self.handleEvent(data, Event.selectMenuEvent.rawValue)
                    }
                } else if initialType == 5 {
                    await self.handleEvent(data, Event.textInputEvent.rawValue)
                }

            case .slashCommandEvent:
                let event = SlashCommandEvent(swiftcord, data: data)

                await listener.onSlashCommandEvent(event: event)

            case .buttonEvent:
                let event = ButtonEvent(swiftcord, data: data)

                await listener.onButtonClickEvent(event: event)

            case .selectMenuEvent:
                let event = SelectMenuEvent(swiftcord, data: data)

                await listener.onSelectMenuEvent(event: event)

            case .userCommandEvent:
                let event = UserCommandEvent(swiftcord, data: data)

                await listener.onUserCommandEvent(event: event)
            case .messageCommandEvent:
                let event = MessageCommandEvent(swiftcord, data: data)

                await listener.onMessageCommandEvent(event: event)
            case .textInputEvent:
                let event = TextInputEvent(swiftcord, data: data)
                
                await listener.onTextInputEvent(event: event)
            }
        }
    }
}
