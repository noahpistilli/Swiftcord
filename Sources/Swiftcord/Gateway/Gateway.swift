//
//  Gateway.swift
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
import WebSocketKit
import NIOPosix
import NIOWebSocket
import NIOCore

protocol Gateway: AnyObject {

    var swiftcord: Swiftcord { get }

    var acksMissed: Int { get set }

    var gatewayUrl: String { get set }

    var heartbeatPayload: Payload { get }

    var heartbeatQueue: DispatchQueue! { get }

    var isConnected: Bool { get set }

    var session: WebSocket? { get set }

    func handleDisconnect(for code: Int) async

    func handlePayload(_ payload: Payload) async

    func heartbeat(at interval: TimeAmount)

    func reconnect() async

    func send(_ text: String, presence: Bool)

    func start() async

    func stop()
    
    var eventLoopGroup: EventLoopGroup { get }

}

extension Gateway {

    /// Starts the gateway connection
    func start() async {
        self.acksMissed = 0
        
        self.swiftcord.trace("Create websocketclient")
        
        self.swiftcord.trace("Before connecting to the websocket")
        WebSocket.connect(
            to: self.gatewayUrl,
            configuration: .init(tlsConfiguration: nil, maxFrameSize: 1 << 31),
            on: self.eventLoopGroup
        ) { ws in
            self.session = ws
            self.isConnected = true
            
            self.onText()
            self.onClose()
            
        }.whenFailure { error in
            self.swiftcord.error("Failed to connect to Discord, attempting reconnect. Error: \(error)")
            Task { await self.start() }
        }
    }
    
    private func onText() {
        self.session?.onText { _, text in
            self.swiftcord.trace("Handle incoming payload: \(text)")
            await self.handlePayload(Payload(with: text))
        }
    }
    
    private func onClose() {
        // TODO: Properly handle on close, this is insanely incorrect
        self.session?.onClose.whenComplete { [weak self] _ in
            guard let self = self else { return }
            Task { await self.start() }
        }
    }
}
