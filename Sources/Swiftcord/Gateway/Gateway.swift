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
import NIO

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

    func heartbeat(at interval: Int) async

    func reconnect() async

    func send(_ text: String, presence: Bool)

    func start() async

    func stop()
    
    var eventLoopGroup: EventLoopGroup { get }

}

extension Gateway {

    /// Starts the gateway connection
    func start() async {
        self.swiftcord.trace("Before creating loopgroup")
        let promise = eventLoopGroup.next().makePromise(of: WebSocketErrorCode.self)

        self.acksMissed = 0
        self.swiftcord.trace("Before force unwrapping URL")
        let url = URL(string: self.gatewayUrl)!
        let path = self.gatewayUrl.components(separatedBy: "/?")[1]

        self.swiftcord.trace("Create websocketclient")
        let wsClient = WebSocketClient(eventLoopGroupProvider: .shared(eventLoopGroup.next()), configuration: .init(tlsConfiguration: .clientDefault, maxFrameSize: 1 << 31))

        self.swiftcord.trace("Before connecting to the websocket")
        try! await wsClient.connect(
            scheme: url.scheme!,
            host: url.host!,
            port: url.port ?? 443,
            path: "/?" + path
        ) { ws in

            self.session = ws
            self.isConnected = true

            self.session?.onText { _, text in
                self.swiftcord.trace("Handle incoming payload: \(text)")
                await self.handlePayload(Payload(with: text))
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
                    } else {
                        self.swiftcord.trace("No closeCode provided by session closure")
                    }
                    break
                case .failure(let error):
                    self.swiftcord.error("Session failed to close: \(error)")
                    break
                }
            }

            self.swiftcord.log("[Swiftcord] Connected to Discord!")
        }.get()

        do {
            let errorCode = try await promise.futureResult.get()
            self.swiftcord.debug("Got errorCode successfully")
            
            switch errorCode {
            case .unknown(let int):
                // Unknown will the codes sent by Discord
                self.swiftcord.debug("Discord error code: \(errorCode). Trying to reconnect")
                await self.handleDisconnect(for: Int(int))
            case .goingAway:
                self.swiftcord.debug("Websocket error code: \(errorCode). Trying to reconnect")
                await self.handleDisconnect(for: 1001)
            case .unexpectedServerError:
                // Usually means the client lost their internet connection
                self.swiftcord.debug("Websocket error code: \(errorCode). Trying to reconnect")
                await self.handleDisconnect(for: 1011)
            case .normalClosure:
                // We always want to keep the bot alive so reconnect
                self.swiftcord.debug("Websocket error code: \(errorCode). Trying to reconnect")
                await self.handleDisconnect(for: 1000)
            default:
                self.swiftcord.error("Unknown Error Code: \(errorCode). Please restart the app.")
            }
        } catch let error {
            self.swiftcord.trace("Failed to retrieve errorcode: \(error)")
        }
    }
}
