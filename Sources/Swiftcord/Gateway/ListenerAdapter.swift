//
//  File.swift
//  
//
//  Created by Noah Pistilli on 2022-01-29.
//

import Foundation

public class ListenerAdapter {
    // Channel Create Events
    public func onChannelCreate(event: TextChannel) {}
    public func onCategoryCreate(event: GuildCategory) {}
    public func onVoiceChannelCreate(event: GuildVoice) {}
    
    // Channel Delete Events
    public func onChannelDelete(event: TextChannel) {}
    public func onCategoryDelete(event: GuildCategory) {}
    public func onVoiceChannelDelete(event: GuildVoice) {}
    
    
    // Channel Update Events
    public func onChannelUpdate(event: TextChannel) {}
    public func onCategoryUpdate(event: GuildCategory) {}
    public func onVoiceChannelUpdate(event: GuildVoice) {}
    public func onChannelPinUpdate(event: Channel, lastPin: Date? = nil) {}
    
    // InteractionEvents
    public func onButtonClickEvent(event: ButtonEvent) {}
    public func onMessageCommandEvent(event: MessageCommandEvent) {}
    public func onSlashCommandEvent(event: SlashCommandEvent) {}
    public func onSelectMenuEvent(event: SelectMenuEvent) {}
    public func onUserCommandEvent(event: UserCommandEvent) {}
    
    // Guild Events
    public func onGuildBan(guild: Guild, user: User) {}
    public func onGuildUnban(guild: Guild, user: User) {}
    public func onGuildCreate(guild: Guild) {}
    public func onGuildDelete(guild: Guild) {}
    public func onGuildMemberJoin(guild: Guild, member: Member) {}
    public func onGuildMemberLeave(guild: Guild, user: User) {}
    public func onGuildReady(guild: Guild) {}
    public func onGuildRoleCreate(guild: Guild, role: Role) {}
    public func onGuildRoleDelete(guild: Guild, role: Role) {}
    public func onGuildAvailable(guild: Guild) {}
    public func onUnavailableGuildDelete(guild: UnavailableGuild) {}
    
    // Guild Update Events
    public func onGuildEmojisUpdate(guild: Guild, emojis: [Emoji]) {}
    public func onGuildIntegrationUpdate(guild: Guild) {}
    public func onGuildMemberUpdate(guild: Guild, member: Member) {}
    public func onGuildRoleUpdate(guild: Guild, role: Role) {}
    public func onGuildUpdate(guild: Guild) {}
    
    // Message Events
    public func onMessageCreate(event: Message) {}
    public func onMessageDelete(messageId: Snowflake, channel: Channel) {}
    public func onMessageBulkDelete(messageIds: [Snowflake], channel: Channel) {}
    public func onMessageReactionAdd(channel: Channel, messageId: Snowflake, userId: Snowflake, emoji: Emoji) {}
    public func onMessageReactionRemove(channel: Channel, messageId: Snowflake, userId: Snowflake, emoji: Emoji) {}
    public func onMessageReactionRemoveAll(messageId: Snowflake, channel: Channel) {}
    
    // Thread Events
    public func onThreadCreate(event: ThreadChannel) {}
    public func onThreadDelete(event: ThreadChannel) {}
    public func onThreadUpdate(event: ThreadChannel) {}
    
    // Voice Events
    public func onVoiceChannelJoin(userId: Snowflake, state: VoiceState) {}
    public func onVoiceChannelLeave(userId: Snowflake) {}
    
    // Generic Events
    public func onPresenceUpdate(member: Member?, presence: Presence) {}
    public func onShardReady(id: Int) {}
    public func onReady(botUser: User) {}
    public func onTypingStart(channel: Channel, userId: Snowflake, time: Date) {}
    public func onUserUpdate(event: User) {}
}
