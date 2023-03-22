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

extension Shard {

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
        guard let ws = self.session else { return }
        ws.onClose.whenComplete { [weak self] _ in
            guard let self = self else { return }
            Task {
                if await self.canReconnect(code: ws.closeCode) {
                    self.swiftcord.log("Close code: \(ws.closeCode)")
                        await self.start()
                } else {
                    return
                }
            }
        }
    }
    
    private func canReconnect(code: WebSocketErrorCode?) -> Bool {
        switch code {
        case let .unknown(_code):
            guard let discordCode = CloseOP(rawValue: Int(_code)) else { return true }
            return discordCode.canReconnect
        default: return true
        }
    }
}
