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
  ) {

    guard let event = Event(rawValue: eventName) else {
      self.swiftcord.log("Received unknown event: \(eventName)")
      return
    }

    switch event {

    /// CHANNEL_CREATE
    case .channelCreate:
      switch data["type"] as! Int {
      case 0:
        let channel = GuildText(self.swiftcord, data)
        self.swiftcord.emit(.channelCreate, with: channel)

      case 1:
        let dm = DM(self.swiftcord, data)
        self.swiftcord.emit(.channelCreate, with: dm)

      case 2:
        let channel = GuildVoice(self.swiftcord, data)
        self.swiftcord.emit(.channelCreate, with: channel)

      case 3:
        let group = GroupDM(self.swiftcord, data)
        self.swiftcord.emit(.channelCreate, with: group)

      case 4:
        let category = GuildCategory(self.swiftcord, data)
        self.swiftcord.emit(.channelCreate, with: category)
      default: return
      }

    /// CHANNEL_DELETE
    case .channelDelete:
      switch data["type"] as! Int {
      case 0, 2, 4:
        let guildId = Snowflake(data["guild_id"])!
        guard let guild = self.swiftcord.guilds[guildId] else {
          return
        }
        let channelId = Snowflake(data["id"])!
        guard let channel = guild.channels.removeValue(forKey: channelId) else {
            return
        }
        self.swiftcord.emit(.channelDelete, with: channel)

      case 1:
        let recipient = (data["recipients"] as! [[String: Any]])[0]
        let userId = Snowflake(recipient["id"])!
        guard let dm = self.swiftcord.dms.removeValue(forKey: userId) else {
          return
        }
        self.swiftcord.emit(.channelDelete, with: dm)

      case 3:
        let channelId = Snowflake(data["id"])!
        guard let group = self.swiftcord.groups.removeValue(forKey: channelId) else {
          return
        }
        self.swiftcord.emit(.channelDelete, with: group)

      default: return
      }

    /// CHANNEL_PINS_UPDATE
    case .channelPinsUpdate:
      let channelId = Snowflake(data["channel_id"])!
      let timestamp = data["last_pin_timestamp"] as? String
      guard let channel = self.swiftcord.getChannel(for: channelId) else {
        return
      }
      self.swiftcord.emit(.channelPinsUpdate, with: (channel, timestamp?.date)
      )

    /// CHANNEL_UPDATE
    case .channelUpdate:
      switch data["type"] as! Int {
      case 0, 2, 4:
        let guildId = Snowflake(data["guild_id"])!
        let channelId = Snowflake(data["id"])!
        guard let channel = self.swiftcord.guilds[guildId]!.channels[channelId] as? Updatable else {
          return
        }
        channel.update(data)
        self.swiftcord.emit(.channelUpdate, with: channel)

      case 3:
        let group = GroupDM(self.swiftcord, data)
        self.swiftcord.groups[group.id] = group
        self.swiftcord.emit(.channelUpdate, with: group)

      default: return
      }

    /// GUILD_BAN_ADD & GUILD_BAN_REMOVE
    case .guildBanAdd, .guildBanRemove:
      let guildId = Snowflake(data["guild_id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      let user = User(self.swiftcord, data["user"] as! [String: Any])
      self.swiftcord.emit(event, with: (guild, user))

    /// GUILD_CREATE
    case .guildCreate:
      let guild = Guild(self.swiftcord, data, self.id)
      self.swiftcord.guilds[guild.id] = guild

      if self.swiftcord.unavailableGuilds[guild.id] != nil {
        self.swiftcord.unavailableGuilds.removeValue(forKey: guild.id)
        self.swiftcord.emit(.guildAvailable, with: guild)
      } else {
        self.swiftcord.emit(.guildCreate, with: guild)
      }

      if self.swiftcord.options.willCacheAllMembers
        && guild.members.count != guild.memberCount {
        self.requestOfflineMembers(for: guild.id)
      }

    /// GUILD_DELETE
    case .guildDelete:
      let guildId = Snowflake(data["id"])!
      guard let guild = self.swiftcord.guilds.removeValue(forKey: guildId) else {
        return
      }

      if data["unavailable"] != nil {
        let unavailableGuild = UnavailableGuild(data, self.id)
        self.swiftcord.unavailableGuilds[guild.id] = unavailableGuild
        self.swiftcord.emit(.guildUnavailable, with: unavailableGuild)
      } else {
        self.swiftcord.emit(.guildDelete, with: guild)
      }

    /// GUILD_EMOJIS_UPDATE
    case .guildEmojisUpdate:
      let emojis = (data["emojis"] as! [[String: Any]]).map(Emoji.init)
      let guildId = Snowflake(data["guild_id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      guild.emojis = emojis
      self.swiftcord.emit(.guildEmojisUpdate, with: (guild, emojis))

    /// GUILD_INTEGRATIONS_UPDATE
    case .guildIntegrationsUpdate:
      let guildId = Snowflake(data["guild_id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      self.swiftcord.emit(.guildIntegrationsUpdate, with: guild)

    /// GUILD_MEMBER_ADD
    case .guildMemberAdd:
      let guildId = Snowflake(data["guild_id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      let member = Member(self.swiftcord, guild, data)
      guild.members[member.user!.id] = member
      self.swiftcord.emit(.guildMemberAdd, with: (guild, member))

    /// GUILD_MEMBER_REMOVE
    case .guildMemberRemove:
      let guildId = Snowflake(data["guild_id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      let user = User(self.swiftcord, data["user"] as! [String: Any])
      guild.members.removeValue(forKey: user.id)
      self.swiftcord.emit(.guildMemberRemove, with: (guild, user))

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
      self.swiftcord.emit(.guildMemberUpdate, with: member)

    /// GUILD_ROLE_CREATE
    case .guildRoleCreate:
      let guildId = Snowflake(data["guild_id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      let role = Role(data["role"] as! [String: Any])
      guild.roles[role.id] = role
      self.swiftcord.emit(.guildRoleCreate, with: (guild, role))

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
      self.swiftcord.emit(.guildRoleDelete, with: (guild, role))

    /// GUILD_ROLE_UPDATE
    case .guildRoleUpdate:
      let guildId = Snowflake(data["guild_id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      let role = Role(data["role"] as! [String: Any])
      guild.roles[role.id] = role
      self.swiftcord.emit(.guildRoleUpdate, with: (guild, role))

    /// GUILD_UPDATE
    case .guildUpdate:
      let guildId = Snowflake(data["id"])!
      guard let guild = self.swiftcord.guilds[guildId] else {
        return
      }
      guild.update(data)
      self.swiftcord.emit(.guildUpdate, with: guild)

    /// MESSAGE_CREATE
    case .messageCreate:

      let msg = Message(self.swiftcord, data)

      if let channel = msg.channel as? GuildText {
        channel.lastMessageId = msg.id
      }

      self.swiftcord.emit(.messageCreate, with: msg)

    /// MESSAGE_DELETE
    case .messageDelete:
      let channelId = Snowflake(data["channel_id"])!
      guard let channel = self.swiftcord.getChannel(for: channelId) else {
        return
      }
      let messageId = Snowflake(data["id"])!
      self.swiftcord.emit(.messageDelete, with: (messageId, channel))

    /// MESSAGE_BULK_DELETE
    case .messageDeleteBulk:
      let channelId = Snowflake(data["channel_id"])!
      guard let channel = self.swiftcord.getChannel(for: channelId) else {
        return
      }
      let messageIds = (data["ids"] as! [String]).map({ Snowflake($0)! })
      self.swiftcord.emit(.messageDeleteBulk, with: (messageIds, channel))

    /// MESSAGE_REACTION_REMOVE_ALL
    case .messageReactionRemoveAll:
      let channelId = Snowflake(data["channel_id"])!
      guard let channel = self.swiftcord.getChannel(for: channelId) else {
        return
      }
      let messageId = Snowflake(data["message_id"])!
      self.swiftcord.emit(.messageReactionRemoveAll, with: (messageId, channel))

    /// MESSAGE_UPDATE
    case .messageUpdate:
      self.swiftcord.emit(.messageUpdate, with: data)

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
      self.swiftcord.emit(.presenceUpdate, with: (userId, presence))

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
      self.swiftcord.emit(.shardReady, with: self.id)

      if self.swiftcord.shardsReady == self.swiftcord.shardCount {
        self.swiftcord.user = User(self.swiftcord, data["user"] as! [String: Any])
        self.swiftcord.emit(.ready, with: self.swiftcord.user!)
      }

    /// MESSAGE_REACTION_ADD, MESSAGE_REACTION_REMOVE
    case .reactionAdd, .reactionRemove:
      let channelId = Snowflake(data["channel_id"])!
      guard let channel = self.swiftcord.getChannel(for: channelId) else {
        return
      }
      let userID = Snowflake(data["user_id"])!
      let messageID = Snowflake(data["message_id"])!
      let emoji = Emoji(data["emoji"] as! [String: Any])
      self.swiftcord.emit(event, with: (channel, userID, messageID, emoji))
        
    case .threadCreate:
        let thread = Thread(swiftcord, data)
        self.swiftcord.emit(.threadCreate, with: thread)
        
    case .threadDelete:
        let thread = Thread(swiftcord, data)
        self.swiftcord.emit(.threadDelete, with: thread)
        
    
    case .threadUpdate:
        let thread = Thread(swiftcord, data)
        self.swiftcord.emit(.threadUpdate, with: thread)

    /// TYPING_START
    case .typingStart:
      #if !os(Linux)
      let timestamp = Date(timeIntervalSince1970: data["timestamp"] as! Double)
      #else
      let timestamp = Date(
        timeIntervalSince1970: Double(data["timestamp"] as! Int)
      )
      #endif
      let channelId = Snowflake(data["channel_id"])!
      guard let channel = self.swiftcord.getChannel(for: channelId) else {
        return
      }
      let userId = Snowflake(data["user_id"])!
      self.swiftcord.emit(.typingStart, with: (channel, userId, timestamp))

    /// USER_UPDATE
    case .userUpdate:
      self.swiftcord.emit(.userUpdate, with: User(self.swiftcord, data))

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

        self.swiftcord.emit(.voiceChannelJoin, with: (userId, voiceState))
      } else {
        guild.voiceStates.removeValue(forKey: userId)
        guild.members[userId]?.voiceState = nil

        self.swiftcord.emit(.voiceChannelLeave, with: userId)
      }

      self.swiftcord.emit(.voiceStateUpdate, with: userId)

    case .voiceServerUpdate:
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
        
        let interactionDict = data["data"] as! [String : Any]
        
        if initialType == 2 {
            let type = interactionDict["type"] as! Int
            // Application Command event
            switch type {
            case 1:
                self.handleEvent(data, Event.slashCommandEvent.rawValue)
            case 2:
                self.handleEvent(data, Event.userCommandEvent.rawValue)
            case 3:
                self.handleEvent(data, Event.messageCommandEvent.rawValue)
            default:
                return
            }

            return
        }
        else if initialType == 3 {
            let type = interactionDict["component_type"] as! Int
            // Message component event (Buttons/Select Boxes)
            if type == 2 {
                self.handleEvent(data, Event.buttonEvent.rawValue)
            }
            else if type == 3 {
                self.handleEvent(data, Event.selectMenuEvent.rawValue)
            }
            
            return
        }
        
        return
        
    case .slashCommandEvent:
        let slashCommand = SlashCommandEvent(swiftcord, data: data)
        
        self.swiftcord.emit(.slashCommandEvent, with: slashCommand)
        return
        
    case .buttonEvent:
        let button = ButtonEvent(swiftcord, data: data)
        
        self.swiftcord.emit(.buttonEvent, with: button)
        return
        
    case .selectMenuEvent:
        let selectBox = SelectMenuEvent(swiftcord, data: data)
        
        self.swiftcord.emit(.selectMenuEvent, with: selectBox)
        return
    case .userCommandEvent:
        let userCommand = UserCommandEvent(swiftcord, data: data)
        
        self.swiftcord.emit(.userCommandEvent, with: userCommand)
    case .messageCommandEvent:
        let messageCommand = MessageCommandEvent(swiftcord, data: data)
        
        self.swiftcord.emit(.messageCommandEvent, with: messageCommand)
    }
  }

}
