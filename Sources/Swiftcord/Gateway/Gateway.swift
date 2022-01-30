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
        let loopgroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let promise = loopgroup.next().makePromise(of: WebSocketErrorCode.self)

        self.acksMissed = 0

        let url = URL(string: self.gatewayUrl)!
        let path = self.gatewayUrl.components(separatedBy: "/?")[1]

        let wsClient = WebSocketClient(eventLoopGroupProvider: .shared(loopgroup.next()), configuration: .init(tlsConfiguration: .clientDefault, maxFrameSize: 1 << 31))

        wsClient.connect(
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
                switch result {
                case .success():
                    self.isConnected = false

                    // If it is nil we just do nothing
                    if let closeCode = self.session?.closeCode {
                        promise.succeed(closeCode)
                    }
                    break
                case .failure(_):
                    break
                }
            }

            print("[Swiftcord] Connected to Discord!")
        }.whenComplete { _ in }

        let errorCode = try! await promise.futureResult.get()

        switch errorCode {
        case .unknown(let int):
            // Unknown will the codes sent by Discord
            await self.handleDisconnect(for: Int(int))
        default:
            print("[Swiftcord] Unknown Error Code: \(errorCode). Please restart the app.")
        }
    }
}
