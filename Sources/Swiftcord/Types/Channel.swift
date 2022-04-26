//
//  Channel.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation

/// Generic Channel structure
public protocol Channel {

    // MARK: Properties

    /// Parent class
    var swiftcord: Swiftcord? { get }

    /// The id of the channel
    var id: Snowflake { get }

    /// Indicates what type of channel this is
    var type: ChannelType { get }

}

public extension Channel {

    // MARK: Functions

    /// Deletes the current channel, whether it be a DMChannel or GuildChannel
    func delete() async throws -> Channel? {
        return try await self.swiftcord?.deleteChannel(self.id)
    }

}

/// Used to distinguish channels that are pure text base and voice channels
public protocol TextChannel: Channel {

    // MARK: Properties

    /// The last message's id
    var lastMessageId: Snowflake? { get }

}

public extension TextChannel {

    // MARK: Functions

    /**
     Adds a reaction (unicode or custom emoji) to message

     - parameter reaction: Unicode or custom emoji reaction
     - parameter messageId: Message to add reaction to
     */
    func addReaction(
        _ reaction: String,
        to messageId: Snowflake
    ) async throws {
        try await self.swiftcord?.addReaction(reaction, to: messageId, in: self.id)
    }

    /**
     Deletes a message from this channel

     - parameter messageId: Message to delete
     */
    func deleteMessage(
        _ messageId: Snowflake
    ) async throws {
        try await self.swiftcord?.deleteMessage(messageId, from: self.id)
    }

    /**
     Bulk deletes messages

     - parameter messages: Array of message ids to delete
     */
    func deleteMessages(
        _ messages: [Snowflake]
    ) async throws {
        try await self.swiftcord?.deleteMessages(messages, from: self.id)
    }

    /**
     Deletes a reaction from message by user

     - parameter reaction: Unicode or custom emoji to delete
     - parameter messageId: Message to delete reaction from
     - parameter userId: If nil, deletes bot's reaction from, else delete a reaction from user
     */
    func deleteReaction(
        _ reaction: String,
        from messageId: Snowflake,
        by userId: Snowflake? = nil
    ) async throws {
        try await self.swiftcord?.deleteReaction(reaction, from: messageId, by: userId, in: self.id)
    }

    /**
     Edits a message's content

     - parameter messageId: Message to edit
     - parameter content: Text to change message to
     */
    func editMessage(
        _ messageId: Snowflake,
        with options: [String: Any]
    ) async throws -> Message? {
        return try await self.swiftcord?.editMessage(messageId, with: options, in: self.id)
    }

    /**
     Gets a message from this channel

     - parameter messageId: Id of message you want to get
     **/
    func getMessage(
        _ messageId: Snowflake
    ) async throws -> Message? {
        return try await self.swiftcord?.getMessage(messageId, from: self.id)
    }

    /**
     Gets an array of messages from this channel

     #### Option Params ####

     - **around**: Message Id to get messages around
     - **before**: Message Id to get messages before this one
     - **after**: Message Id to get messages after this one
     - **limit**: Number of how many messages you want to get (1-100)

     - parameter options: Dictionary containing optional options regarding how many messages, or when to get them
     **/
    func getMessages(
        with options: [String: Any]? = nil
    ) async throws -> [Message]? {
        return try await self.swiftcord?.getMessages(from: self.id, with: options)
    }

    /**
     Gets an array of users who used reaction from message

     - parameter reaction: Unicode or custom emoji to get
     - parameter messageId: Message to get reaction users from
     */
    func getReaction(
        _ reaction: String,
        from messageId: Snowflake
    ) async throws -> [User]? {
        return try await self.swiftcord?.getReaction(reaction, from: messageId, in: self.id)
    }

    /// Get Pinned messages for this channel
    func getPinnedMessages() async throws -> [Message]? {
        return try await self.swiftcord?.getPinnedMessages(from: self.id)
    }

    /**
     Pins a message to this channel

     - parameter messageId: Message to pin
     */
    func pin(
        _ messageId: Snowflake
    ) async throws {
        try await self.swiftcord?.pin(messageId, in: self.id)
    }

    /**
     Sends a message to channel

     - parameter message: String to send as message
     */
    func send(
        _ message: String
    ) async throws -> Message? {
        return try await self.swiftcord?.send(message, to: self.id)
    }

    /**
     Sends a message to channel

     - parameter message: Dictionary containing info on message to send
     */
    func send(
        _ message: [String: Any],
        then completion: ((Message?, RequestError?) -> Void)? = nil
    ) async throws -> Message? {
        return try await self.swiftcord?.send(message, to: self.id)
    }

    /**
     Sends a message to channel

     - parameter message: Embed to send as message
     */
    func send(
        _ message: EmbedBuilder
    ) async throws -> Message? {
        return try await self.swiftcord?.send(message, to: self.id)
    }

    /**
     Sends a button to channel

     - parameter message: Embed to send as message
     */
    func send(
        _ message: ButtonBuilder
    ) async throws -> Message? {
        return try await self.swiftcord?.send(message, to: self.id)
    }

    /**
     Sends a Select Menu to channel

     - parameter message: Embed to send as message
     */
    func send(
        _ message: SelectMenuBuilder
    ) async throws -> Message? {
        return try await self.swiftcord?.send(message, to: self.id)
    }

    /**
     Unpins a pinned message from this channel

     - parameter messageId: Pinned message to unpin
     */
    func unpin(
        _ messageId: Snowflake
    ) async throws {
        try await self.swiftcord?.unpin(messageId, from: self.id)
    }

}

/// Distinguishes Guild channels over dm type channels
public protocol GuildChannel: AnyObject, Channel {

    // MARK: Properties

    /// Channel Category this channel belongs to
    var category: GuildCategory? { get }

    /// Guild this channel belongs to
    var guild: Guild? { get }

    /// Name of the channel
    var name: String? { get }

    /// The channel id of the category that owns this channel
    var parentId: Snowflake? { get }

    /// Collection of overwrites mapped by `OverwriteID`
    var permissionOverwrites: [Snowflake: Overwrite] { get }

    /// Position the channel is in guild
    var position: Int? { get }

}

/// Used to indicate the type of channel
public enum ChannelType: Int {

    /// This is a regular Guild Text Channel (`GuildChannel`)
    case guildText

    /// This is a 1 on 1 DM with a user (`DMChannel`)
    case dm

    /// This is the famous Guild Voice Channel (`GuildChannel`)
    case guildVoice

    /// This is a Group DM Channel (`GroupChannel`)
    case groupDM

    /// This is a Guild Category Channel (`GuildCategory`)
    case guildCategory

    /// This is a Guild Announcement Channel (`GuildChannel`)
    case guildNews

    /// This is a Guild Store Channel. Bots cannot interact with this channel.
    case guildStore

    /// This is a thread within a `guildNews` channel. (`Thread`)
    case guildNewsThread = 10

    /// This is a thread within a public `guildText` channel. (`Thread`)
    case guildPublicThread

    /// This is a thread within a `guildText` channel that is only accessible by members with
    /// `MANAGE_THREADS` permission or if they were invited. (`Thread`)
    case guildPrivateThread

    /// Guild Stage Channel
    case guildStage
}
