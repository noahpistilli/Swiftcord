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

}

extension Gateway {

    /// Starts the gateway connection
    func start() async {
        self.swiftcord.warn("Before creating loopgroup")
        let loopgroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let promise = loopgroup.next().makePromise(of: WebSocketErrorCode.self)

        self.acksMissed = 0
        self.swiftcord.warn("Before force unwrapping URL")
        let url = URL(string: self.gatewayUrl)!
        let path = self.gatewayUrl.components(separatedBy: "/?")[1]

        self.swiftcord.warn("Create websocketclient")
        let wsClient = WebSocketClient(eventLoopGroupProvider: .shared(loopgroup.next()), configuration: .init(tlsConfiguration: .clientDefault, maxFrameSize: 1 << 31))

        self.swiftcord.warn("Before connecting to the websocket")
        try! await wsClient.connect(
            scheme: url.scheme!,
            host: url.host!,
            port: url.port ?? 443,
            path: "/?" + path
        ) { ws in

            self.session = ws
            self.isConnected = true

            self.session?.onText { _, text in
                await self.handlePayload(Payload(with: text))
            }

            self.session?.onClose.whenComplete { result in
                self.swiftcord.warn("onclose.whencomplete")
                switch result {
                case .success():
                    self.isConnected = false
                    self.swiftcord.warn("Successfull onclose")
                    // If it is nil we just do nothing
                    if let closeCode = self.session?.closeCode {
                        promise.succeed(closeCode)
                        self.swiftcord.warn("promise succeeded with closeCode")
                    }
                    break
                case .failure(_):
                    self.swiftcord.warn("session onclose failed")
                    break
                }
            }

            print("[Swiftcord] Connected to Discord!")
        }.get()

        let errorCode = try! await promise.futureResult.get()
        self.swiftcord.warn("Got errorCode successfully")
        
        do {
            try await loopgroup.shutdownGracefully()
            self.swiftcord.warn("loopgroup shutdown successfully")
        } catch {
            self.swiftcord.warn("loopgroup not shutdown")
        }
        
        switch errorCode {
        case .unknown(let int):
            // Unknown will the codes sent by Discord
            await self.handleDisconnect(for: Int(int))

        case .unexpectedServerError:
            // Usually means the client lost their internet connection
            await self.handleDisconnect(for: 1011)
        default:
            self.swiftcord.error("Unknown Error Code: \(errorCode). Please restart the app.")
        }
    }
}
