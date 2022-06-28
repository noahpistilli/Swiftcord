//
//  VoiceClient.swift
//  
//
//  Created by Noah Pistilli on 2022-05-09.
//

import Foundation
import NIOCore
import WebSocketKit
import Sodium
import Opus

public class VoiceClient: VoiceGateway {
    
    /// The interface used for the UDP socket.
    var networkingInterface: NIONetworkDevice
    
    /// How long the audio stream has been streaming for
    var timestamp: UInt32 = 0
    
    /// Amount of times audio has been sent over the UDP socket
    var sequence: UInt16 = 0
    
    /// The callback handler for the UDP socket
    var messageHandler = MessageHandler()

    /// Padding for the nonce used for libsodium
    let padding = [UInt8](repeating: 0x00, count: 12)
    
    /// Number of heartbeat acks in the gateway
    var acksMissed = 0
    
    var ssrc: UInt32 = 0
    
    /// IP that the UDP socket will use to send audio to
    var endpointIp = ""
    
    /// Port that the UDP socket will use to send audio to
    var voicePort = 0
    
    /// IP that Discord gives us to recieve voice
    var ip = ""
    
    /// Port that Discord gives us to recieve voice
    var port = 0
    
    /// Heartbeat to send
    var heartbeatPayload: VoicePayload {
        return VoicePayload(op: .heartbeat, data: self.lastSeq ?? NSNull())
    }
    
    /// Last sequence. This is sent by Discord sometimes
    var lastSeq: Int?
    
    /// Voice token
    var token: String
    
    /// ID of the guild that the current voice connection is in
    var guildId: Snowflake
    
    let heartbeatQueue: DispatchQueue!
    
    /// Is the Websocket connected to the gateway
    var isConnected = false
    
    /// Websocket session
    var session: WebSocket?
    
    /// Parent class
    var swiftcord: Swiftcord
    
    var gatewayUrl: String
    
    var eventLoopGroup: EventLoopGroup
    
    /// Voice session ID
    var sessionId: String
    
    /// The UDP socket
    var udpConnection: NIO.Channel?
    
    /// Secret key used for encoding audio with libsodium
    var secretKey = [UInt8]()
    
    /// Global Opus encoder
    var opus: OpusEncoder
    
    // MARK: Initializer
    init(_ swiftcord: Swiftcord, gatewayUrl: String, token: String, guildId: Snowflake, sessionId: String, eventLoopGroup: EventLoopGroup) throws {
        // Find if we have a suitable networking interface available.
        let matchingInterfaces = try! System.enumerateDevices().filter {
            // find an IPv4 interface named en0 that has a broadcast address.
            $0.name == "en0" && $0.broadcastAddress != nil
        }
        
        guard let en0Interface = matchingInterfaces.first else {
            throw VoiceError.noNetworkingInterfaceFound
        }
        
        self.networkingInterface = en0Interface
        
        self.swiftcord = swiftcord
        self.gatewayUrl = gatewayUrl
        self.eventLoopGroup = eventLoopGroup
        self.token = token
        self.guildId = guildId
        self.sessionId = sessionId
        
        self.heartbeatQueue = DispatchQueue(
            label: "io.github.SketchMaster2001.Swiftcord.VoiceClient.\(guildId).heartbeat",
            qos: .userInitiated
        )
        
        self.opus = try! OpusEncoder(sampleRate: 48000, channels: 2, bitrate: 128000)
    }
    
    func disconnect() async {
        // Shut down the websocket and UDP connection.
        try! await self.session?.close()
        try! await self.udpConnection?.close()
        
        // Now disconnect us from the voice channel.
        self.swiftcord.guilds[self.guildId]?.leaveVoiceChannel()
    }
    
    func handlePayload(_ payload: VoicePayload) async {

      if let sequenceNumber = payload.s {
        self.lastSeq = sequenceNumber
      }

      guard payload.t != nil else {
        await self.handleVoiceGateway(payload)
        return
      }

      guard payload.d is [String: Any] else {
        return
      }
    }
    
    func identify() {
        let data: [String: Any] = [
            "server_id": self.guildId.rawValue,
            "user_id": self.swiftcord.user!.id.rawValue,
            "session_id": self.sessionId,
            "token": self.token,
        ]
        
        let identity = VoicePayload(
            op: .identify,
            data: data
        ).encode()

        self.send(identity)
    }
    
    func sendSpeaking(_ speaking: SpeakingState = .voice) async {
        let speakingObject: [String: Any] = [
            "speaking": speaking.rawValue,
            "delay": 0
        ]

        self.send(VoicePayload(op: .speaking, data: speakingObject).encode())
    }
    
    func selectProtocol(ip: String, port: Int) {
        let payloadData: [String: Any] = [
            "protocol": "udp",
            "data": [
                "address": self.ip,
                "port": self.port,
                "mode": "xsalsa20_poly1305"
            ]
        ]
        
        self.send(VoicePayload(op: .selectProtocol, data: payloadData).encode())
    }
    
    private func createRTPHeader() -> [UInt8] {
        let header = UnsafeMutableRawBufferPointer.allocate(byteCount: 12, alignment: MemoryLayout<Int>.alignment)

        defer { header.deallocate() }

        header.storeBytes(of: 0x80, as: UInt8.self)
        header.storeBytes(of: 0x78, toByteOffset: 1, as: UInt8.self)
        header.storeBytes(of: self.sequence.bigEndian, toByteOffset: 2, as: UInt16.self)
        header.storeBytes(of: self.timestamp.bigEndian, toByteOffset: 4, as: UInt32.self)
        header.storeBytes(of: UInt32(self.ssrc.bigEndian), toByteOffset: 8, as: UInt32.self)

        return Array(header)
    }
    
    private func createVoicePacket(_ data: [UInt8]) throws -> [UInt8] {
        let packetSize = Int(crypto_secretbox_MACBYTES) + data.count
        let encrypted = UnsafeMutablePointer<UInt8>.allocate(capacity: packetSize)
        let rtpHeader = self.createRTPHeader()
        var nonce = rtpHeader + self.padding
        var buf = data

        defer { encrypted.deallocate() }

        let success = crypto_secretbox_easy(encrypted, &buf, UInt64(buf.count), &nonce, &self.secretKey)
        
        guard success != -1 else { throw ResponseError.other(RequestError("url stuff")) }
        
        return rtpHeader + Array(UnsafeBufferPointer(start: encrypted, count: packetSize))
    }
    
    func send(_ text: String) {
        self.session?.send(text)
    }
    
    func checkedAdd(_ attr: inout UInt32, value: UInt32, limit: Int) {
        if attr + value > limit {
            attr = 0
        } else {
            attr += value
        }
    }
    
    func checkedAdd(_ attr: inout UInt16, value: UInt16, limit: Int) {
        if attr + value > limit {
            attr = 0
        } else {
            attr += value
        }
    }

    func sendAudioPacket(voiceData: Data, isOpus: Bool) async throws {
        self.checkedAdd(&self.sequence, value: 1, limit: 65535)
        
        var encoded = [UInt8]()
        
        if isOpus {
            encoded = [UInt8](voiceData)
        } else {
            // Encode to Opus
            encoded = try opus.encode(voiceData)
        }
        
        let packet = try createVoicePacket(encoded)
        
        let data = Data(packet)
        
        try await self.sendToUDP(data: data)
        self.checkedAdd(&self.timestamp, value: 960, limit: 4294967295)
    }
}
