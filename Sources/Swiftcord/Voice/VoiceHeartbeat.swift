//
//  VoiceHeartbeat.swift
//  
//
//  Created by Noah Pistilli on 2022-05-09.
//

import Foundation
import Dispatch

extension VoiceGateway {
    
    func heartbeat(at interval: Int) {
        guard self.isConnected else {
            return
        }

        guard self.acksMissed < 3 else {
            Task {
                self.swiftcord.debug("Did not receive ACK from server, reconnecting...")
                // await self.reconnect()
            }
            return
        }

        self.acksMissed += 1

        self.send(self.heartbeatPayload.encode())

        self.heartbeatQueue.asyncAfter(
            deadline: .now() + .milliseconds(interval)
        ) { [unowned self] in
            self.heartbeat(at: interval)
        }
    }
}
