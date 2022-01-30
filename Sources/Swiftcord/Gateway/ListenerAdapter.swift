//
//  ListenerAdapter.swift
//
//
//  Created by Noah Pistilli on 2022-01-29.
//

import Foundation

open class ListenerAdapter {
    // Channel Create Events
    open func onChannelCreate(event: TextChannel) async {}
    open func onCategoryCreate(event: GuildCategory) async {}
    open func onVoiceChannelCreate(event: GuildVoice) async {}

    // Channel Delete Events
    open func onChannelDelete(event: TextChannel) async {}
    open func onCategoryDelete(event: GuildCategory) async {}
    open func onVoiceChannelDelete(event: GuildVoice) async {}

    // Channel Update Events
    open func onChannelUpdate(event: TextChannel) async {}
    open func onCategoryUpdate(event: GuildCategory) async {}
    open func onVoiceChannelUpdate(event: GuildVoice) async {}
    open func onChannelPinUpdate(event: Channel, lastPin: Date? = nil) async {}

    // InteractionEvents
    open func onButtonClickEvent(event: ButtonEvent) async {}
    open func onMessageCommandEvent(event: MessageCommandEvent) async {}
    open func onSlashCommandEvent(event: SlashCommandEvent) async {}
    open func onSelectMenuEvent(event: SelectMenuEvent) async {}
    open func onUserCommandEvent(event: UserCommandEvent) async {}

    // Guild Events
    open func onGuildBan(guild: Guild, user: User) async {}
    open func onGuildUnban(guild: Guild, user: User) async {}
    open func onGuildCreate(guild: Guild) async {}
    open func onGuildDelete(guild: Guild) async {}
    open func onGuildMemberJoin(guild: Guild, member: Member) async {}
    open func onGuildMemberLeave(guild: Guild, user: User) async {}
    open func onGuildReady(guild: Guild) async {}
    open func onGuildRoleCreate(guild: Guild, role: Role) async {}
    open func onGuildRoleDelete(guild: Guild, role: Role) async {}
    open func onGuildAvailable(guild: Guild) async {}
    open func onUnavailableGuildDelete(guild: UnavailableGuild) async {}

    // Guild Update Events
    open func onGuildEmojisUpdate(guild: Guild, emojis: [Emoji]) async {}
    open func onGuildIntegrationUpdate(guild: Guild) async {}
    open func onGuildMemberUpdate(guild: Guild, member: Member) async {}
    open func onGuildRoleUpdate(guild: Guild, role: Role) async {}
    open func onGuildUpdate(guild: Guild) async {}

    // Message Events
    open func onMessageCreate(event: Message) async {}
    open func onMessageDelete(messageId: Snowflake, channel: Channel) async {}
    open func onMessageBulkDelete(messageIds: [Snowflake], channel: Channel) async {}
    open func onMessageReactionAdd(channel: Channel, messageId: Snowflake, userId: Snowflake, emoji: Emoji) async {}
    open func onMessageReactionRemove(channel: Channel, messageId: Snowflake, userId: Snowflake, emoji: Emoji) async {}
    open func onMessageReactionRemoveAll(messageId: Snowflake, channel: Channel) async {}

    // Thread Events
    open func onThreadCreate(event: ThreadChannel) async {}
    open func onThreadDelete(event: ThreadChannel) async {}
    open func onThreadUpdate(event: ThreadChannel) async {}

    // Voice Events
    open func onVoiceChannelJoin(userId: Snowflake, state: VoiceState) async {}
    open func onVoiceChannelLeave(userId: Snowflake) async {}

    // Generic Events
    open func onPresenceUpdate(member: Member?, presence: Presence) async {}
    open func onShardReady(id: Int) async {}
    open func onReady(botUser: User) async {}
    open func onTypingStart(channel: Channel, userId: Snowflake, time: Date) async {}
    open func onUserUpdate(event: User) async {}

    public init() {}
}
