//
//  Options.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

/// Swiftcord Options structure
public struct SwiftcordOptions {

    // MARK: Properties

    /// Whether or not the application is a bot or oauth bearer
    public var isBot = true

    /// Whether or not this bot will distribute it's shards across multiple process/machines
    public var isDistributed = false

    /// Whether or not caching offline members is allowed
    public var willCacheAllMembers = false

    /// Whether or not the bot will log to console
    public var willLog = false

    /// Whether or not to shard this bot
    public var willShard = true

    // MARK: Initializer

    /// Creates a default SwiftcordOptions
    public init(
        isBot: Bool = true,
        isDistributed: Bool = false,
        willCacheAllMembers: Bool = false,
        willLog: Bool = false,
        willShard: Bool = true
    ) {
        self.isBot = isBot
        self.isDistributed = isDistributed
        self.willCacheAllMembers = willCacheAllMembers
        self.willLog = willLog
        self.willShard = willShard
    }

}
