//
//  Gateway.swift
//  Sword
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

protocol Gateway: AnyObject {

  var acksMissed: Int { get set }
  
  var gatewayUrl: String { get set }

  var heartbeatPayload: Payload { get }
  
  var heartbeatQueue: DispatchQueue! { get }
  
  var isConnected: Bool { get set }
  
  var session: WebSocket? { get set }
  
  func handleDisconnect(for code: Int)
  
  func handlePayload(_ payload: Payload)
  
  func heartbeat(at interval: Int)
  
  func reconnect()
  
  func send(_ text: String, presence: Bool)
  
  func start()

  func stop()

}

extension Gateway {
  
  /// Starts the gateway connection
  func start() {
      let loopgroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
      
      self.acksMissed = 0
      
      let url = URL(string: self.gatewayUrl)!
      
      let wsClient = WebSocketClient(eventLoopGroupProvider: .shared(loopgroup.next()), configuration: .init(tlsConfiguration: .clientDefault, maxFrameSize: 1 << 31))
      
      let future = wsClient.connect(
        scheme: url.scheme!,
        host: url.host!,
        port: url.port ?? 443
      ) { ws in
          
          self.session = ws
          self.isConnected = true
          self.webSocketEventHandlers()
      }
      
      future.whenFailure { err in
          print((err as NSError).code)
          self.handleDisconnect(for: (err as NSError).code)
      }
  }
    
    func webSocketEventHandlers() {
        self.session?.onText { _, text in
            self.handlePayload(Payload(with: text))
        }
        
        self.session?.onClose.whenSuccess {
            self.isConnected = false
        }

        self.session?.onClose.whenFailure { err in
            print((err as NSError).code)
            self.isConnected = false
            self.handleDisconnect(for: (err as NSError).code)
        }
    }
}
