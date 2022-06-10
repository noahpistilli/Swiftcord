//
//  VoiceGateway.swift
//  
//
//  Created by Noah Pistilli on 2022-05-09.
//

import Foundation
import NIOPosix
import NIO
import WebSocketKit
import NIOWebSocket

protocol VoiceGateway: AnyObject {
    
    var heartbeatPayload: VoicePayload { get }
    
    var acksMissed: Int { get set }
    
    var heartbeatQueue: DispatchQueue! { get }
    
    var isConnected: Bool { get set }
    
    var session: WebSocket? { get set }
    
    var swiftcord: Swiftcord { get }
    
    var token: String { get }
    
    var guildId: Snowflake { get }
    
    var gatewayUrl: String { get }
    
    func send(_ text: String)
    
    func handlePayload(_ payload: VoicePayload) async
    
    func handleVoiceGateway(_ payload: VoicePayload) async
    
    var eventLoopGroup: EventLoopGroup { get }
}

extension VoiceGateway {
    
    func start() async {
        self.swiftcord.trace("Before creating loopgroup")
        let promise = eventLoopGroup.next().makePromise(of: WebSocketErrorCode.self)
        
        self.swiftcord.trace("Before force unwrapping URL")
        let url = URL(string: self.gatewayUrl)!

        self.swiftcord.trace("Create websocketclient")
        let wsClient = WebSocketClient(eventLoopGroupProvider: .shared(eventLoopGroup.next()), configuration: .init(tlsConfiguration: .clientDefault, maxFrameSize: 1 << 31))

        self.swiftcord.trace("Before connecting to the websocket")
        try! await wsClient.connect(
            scheme: url.scheme!,
            host: url.host!,
            port: url.port ?? 443,
            path: "/?v=4"
        ) { ws in

            self.session = ws
            self.isConnected = true

            self.session?.onText { _, text in
                print(text)
                self.swiftcord.trace("Handle incoming payload: \(text)")
                await self.handlePayload(VoicePayload(with: text))
            }

            self.session?.onClose.whenComplete { result in
                self.swiftcord.trace("onclose.whencomplete")
                switch result {
                case .success():
                    self.isConnected = false
                    self.swiftcord.trace("Successfull onclose")
                    // If it is nil we just do nothing
                    if let closeCode = self.session?.closeCode {
                        promise.succeed(closeCode)
                        self.swiftcord.trace("promise succeeded with closeCode")
                    }
                    break
                case .failure(_):
                    self.swiftcord.trace("session onclose failed")
                    break
                }
            }

            self.swiftcord.log("[Swiftcord] Connected to Discord!")
        }.get()

        let errorCode = try! await promise.futureResult.get()
        self.swiftcord.debug("Got errorCode successfully")
    }
    
}
