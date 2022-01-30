//
//  Endpoints.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

enum Endpoint {

    case gateway

    case addPinnedChannelMessage(Snowflake, Snowflake)

    case beginGuildPrune(Snowflake)

    case bulkDeleteMessages(Snowflake)

    case createChannelInvite(Snowflake)

    case createDM

    case createGuild

    case createGuildBan(Snowflake, Snowflake)

    case createGuildChannel(Snowflake)

    case createGuildIntegration(Snowflake)

    case createGuildRole(Snowflake)

    case createGuildScheduledEvent(Snowflake)

    case createMessage(Snowflake)

    case createReaction(Snowflake, Snowflake, String)

    case createWebhook(Snowflake)

    case deleteAllReactions(Snowflake, Snowflake)

    case deleteChannel(Snowflake)

    case deleteChannelPermission(Snowflake, Snowflake)

    case deleteGlobalSlashCommand(Snowflake, Snowflake)

    case deleteGuild(Snowflake)

    case deleteGuildEmoji(Snowflake, Snowflake)

    case deleteGuildApplicationCommand(Snowflake, Snowflake, Snowflake)

    case deleteGuildIntegration(Snowflake, Snowflake)

    case deleteGuildRole(Snowflake, Snowflake)

    case deleteInvite(invite: String)

    case deleteMessage(Snowflake, Snowflake)

    case deleteOwnReaction(Snowflake, Snowflake, String)

    case deletePinnedChannelMessage(Snowflake, Snowflake)

    case deleteUserReaction(Snowflake, Snowflake, String, Snowflake)

    case deleteWebhook(Snowflake, String?)

    case editChannelPermissions(Snowflake, Snowflake)

    case editMessage(Snowflake, Snowflake)

    case editWebhook(Snowflake, String?)

    case executeSlackWebhook(Snowflake, String)

    case executeWebhook(Snowflake, String)

    case getChannel(Snowflake)

    case getChannelInvites(Snowflake)

    case getChannelMessage(Snowflake, Snowflake)

    case getChannelMessages(Snowflake)

    case getChannelWebhooks(Snowflake)

    case getCurrentUser

    case getCurrentUserGuilds

    case getGuild(Snowflake)

    case getGuildAuditLogs(Snowflake)

    case getGuildBans(Snowflake)

    case getGuildChannels(Snowflake)

    case getGuildEmbed(Snowflake)

    case getGuildEmoji(Snowflake, Snowflake)

    case getGuildEmojis(Snowflake)

    case getGuildIntegrations(Snowflake)

    case getGuildInvites(Snowflake)

    case getGuildMember(Snowflake, Snowflake)

    case getGuildPruneCount(Snowflake)

    case getGuildRoles(Snowflake)

    case getGuildSticker(Snowflake, Snowflake)

    case getGuildStickers(Snowflake)

    case getGuildVoiceRegions(Snowflake)

    case getGuildWebhooks(Snowflake)

    case getInvite(String)

    case getPinnedMessages(Snowflake)

    case getReactions(Snowflake, Snowflake, String)

    case getScheduledEvent(Snowflake)

    case getSticker(Snowflake)

    case getThreads(Snowflake)

    case getUser(Snowflake)

    case getUserConnections

    case getUserDM

    case getWebhook(Snowflake, String?)

    case groupDMRemoveRecipient(Snowflake, Snowflake)

    case leaveGuild(Snowflake)

    case listGuildMembers(Snowflake)

    case modifyChannel(Snowflake)

    case modifyCurrentUser

    case modifyGuild(Snowflake)

    case modifyGuildChannelPositions(Snowflake)

    case modifyGuildEmbed(Snowflake)

    case modifyGuildEmoji(Snowflake, Snowflake)

    case modifyGuildIntegration(Snowflake, Snowflake)

    case modifyGuildMember(Snowflake, Snowflake)

    case modifyGuildRole(Snowflake, Snowflake)

    case modifyGuildRolePositions(Snowflake)

    case modifyWebhook(Snowflake, String?)

    case removeGuildBan(Snowflake, Snowflake)

    case removeGuildMember(Snowflake, Snowflake)

    case replyToInteraction(Snowflake, String)

    case replyToDeferedInteraction(Snowflake, String)

    case syncGuildIntegration(Snowflake, Snowflake)

    case triggerTypingIndicator(Snowflake)

    case uploadEmoji(Snowflake)

    case uploadGuildApplicationCommand(Snowflake, Snowflake)

    case uploadGlobalApplicationCommand(Snowflake)
}
