//
//  Shard.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//
import Foundation
import Dispatch

import WebSocketKit

/// WS class
class Shard: Gateway {

    // MARK: Properties
    /// Gateway URL for gateway
    var gatewayUrl = ""

    /// Global Event Rate Limiter
    let globalBucket: Bucket

    /// Heartbeat to send
    var heartbeatPayload: Payload {
        return Payload(op: .heartbeat, data: self.lastSeq ?? NSNull())
    }

    /// The dispatch queue to handle sending heartbeats
    let heartbeatQueue: DispatchQueue!

    /// ID of shard
    let id: Int

    /// Whether or not the shard is connected to gateway
    var isConnected = false

    /// The last sequence sent by Discord
    var lastSeq: Int?

    /// Presence Event Rate Limiter
    let presenceBucket: Bucket

    /// Whether or not the shard is reconnecting
    var isReconnecting = false

    /// WS
    var session: WebSocket?

    /// Session ID of gateway
    var sessionId: String?

    /// Amount of shards bot should be connected to
    let shardCount: Int

    /// Parent class
    unowned let swiftcord: Swiftcord

    /// Number of missed heartbeat ACKs
    var acksMissed = 0

    // MARK: Initializer
    /**
     Creates Shard Handler
     - parameter swiftcord: Parent class
     - parameter id: ID of the current shard
     - parameter shardCount: Total number of shards bot needs to be connected to
     */
    init(_ swiftcord: Swiftcord, _ id: Int, _ shardCount: Int, _ gatewayUrl: String) {
        self.swiftcord = swiftcord
        self.id = id
        self.shardCount = shardCount
        self.gatewayUrl = gatewayUrl

        self.heartbeatQueue = DispatchQueue(
            label: "io.github.SketchMaster2001.Swiftcord.shard.\(id).heartbeat",
            qos: .userInitiated
        )

        self.globalBucket = Bucket(
            name: "io.github.SketchMaster2001.Swiftcord.shard.\(id).global",
            limit: 120,
            interval: 60
        )

        self.presenceBucket = Bucket(
            name: "io.github.SketchMaster2001.Swiftcord.shard.\(id).presence",
            limit: 5,
            interval: 60
        )
    }

    // MARK: Functions
    /**
     Handles gateway events from WS connection with Discord
     - parameter payload: Payload struct that Discord sent as JSON
     */
    func handlePayload(_ payload: Payload) async {

        if let sequenceNumber = payload.s {
            self.lastSeq = sequenceNumber
        }

        guard payload.t != nil else {
            await self.handleGateway(payload)
            return
        }

        guard payload.d is [String: Any] else {
            return
        }

        await self.handleEvent(payload.d as! [String: Any], payload.t!)
        self.swiftcord.emit(.payload, with: payload.encode())
    }

    /**
     Handles gateway disconnects

     - parameter code: Close code for the gateway closing
     */
    func handleDisconnect(for code: Int) async {
        self.isReconnecting = true

        self.swiftcord.emit(.disconnect, with: self.id)
        self.swiftcord.warn("status of the bot to disconnected")
        
        guard let closeCode = CloseOP(rawValue: code) else {
            self.swiftcord.log("Connection closed with unrecognized response \(code).")

            await self.reconnect()

            return
        }

        switch closeCode {
        case .authenticationFailed:
            self.swiftcord.error("Invalid Bot Token")
            break

        case .invalidShard:
            self.swiftcord.warn("Invalid Shard (We messed up here. Try again.)")
            break

        case .noInternet:
            try! await Task.sleep(seconds: 10)
            self.swiftcord.warn("Detected a loss of internet...")
            await self.reconnect()

        case .shardingRequired:
            self.swiftcord.error("Sharding is required for this bot to run correctly.")
            break

        case .invalidAPIVersion:
            // This should never happen ever
            self.swiftcord.error("The API version sent to Discord is incorrect. Something is seriously wrong here. Please report this.")

        case .invalidIntents:
            // This also should never happen
            self.swiftcord.error("The intents sent to Discord are incorrect. Something is seriously wrong here. Please report this.")

        case .disallowedIntents:
            self.swiftcord.error("You tried to subscribe to an intent you are not authorized to use. Please remove that intent.")
            break

        case .unexpectedServerError:
            self.swiftcord.warn("Unexpected server error, check your internet connection. Reconnecting in 10 seconds")
            try! await Task.sleep(seconds: 10)
            await self.reconnect()

        default:
            await self.reconnect()
        }
    }

    /// Sends shard identity to WS connection
    func identify() {
        #if os(macOS)
        let osName = "macOS"
        #elseif os(Linux)
        let osName = "Linux"
        #elseif os(iOS)
        let osName = "iOS"
        #elseif os(watchOS)
        let osName = "watchOS"
        #elseif os(tvOS)
        let osName = "tvOS"
        #endif

        var data: [String: Any] = [
            "token": self.swiftcord.token,
            "intents": self.swiftcord.intents,
            "properties": [
                "$os": osName,
                "$browser": "Swiftcord",
                "$device": "Swiftcord"
            ],
            "compress": false,
            "large_threshold": 250,
            "shard": [
                self.id, self.shardCount
            ]
        ]

        if let presence = self.swiftcord.presence {
            data["presence"] = presence
        }

        let identity = Payload(
            op: .identify,
            data: data
        ).encode()

        self.send(identity)
    }

    #if os(macOS) || os(Linux)

    /**
     Sends a payload to socket telling it we want to join a voice channel
     - parameter channelId: Channel to join
     - parameter guildId: Guild that the channel belongs to
     */
    func joinVoiceChannel(_ channelId: Snowflake, in guildId: Snowflake) {
        let payload = Payload(
            op: .voiceStateUpdate,
            data: [
                "guild_id": guildId.description,
                "channel_id": channelId.description,
                "self_mute": false,
                "self_deaf": false
            ]
        ).encode()

        self.send(payload)
    }

    /**
     Sends a payload to socket telling it we want to leave a voice channel
     - parameter guildId: Guild we want to remove bot from
     */
    func leaveVoiceChannel(in guildId: Snowflake) {
        let payload = Payload(
            op: .voiceStateUpdate,
            data: [
                "guild_id": guildId.description,
                "channel_id": NSNull(),
                "self_mute": false,
                "self_deaf": false
            ]
        ).encode()

        self.send(payload)
    }

    #endif

    /// Used to reconnect to gateway
    func reconnect() async {
        if self.isConnected {
            _ = try? await self.session?.close()
            self.swiftcord.warn("Connection successfully closed")
        }

        self.isConnected = false
        self.acksMissed = 0

        self.swiftcord.log("Disconnected from gateway... Resuming session")

        await self.start()
    }

    /// Function to send packet to server to request for offline members for requested guild
    func requestOfflineMembers(for guildId: Snowflake) {
        let payload = Payload(
            op: .requestGuildMember,
            data: [
                "guild_id": guildId.description,
                "query": "",
                "limit": 0
            ]
        ).encode()

        self.send(payload)
    }

    /**
     Sends a payload through WS connection
     - parameter text: JSON text to send through WS connection
     - parameter presence: Whether or not this WS payload updates shard presence
     */
    func send(_ text: String, presence: Bool = false) {
        let item = DispatchWorkItem { [unowned self] in
            self.session?.send(text)
        }

        presence ? self.presenceBucket.queue(item) : self.globalBucket.queue(item)
    }

    /// Used to stop WS connection
    func stop() {
        _ = self.session?.close(code: .goingAway)

        self.isConnected = false
        self.isReconnecting = false
        self.acksMissed = 0

        self.swiftcord.log("Stopping gateway connection...")
    }

}
