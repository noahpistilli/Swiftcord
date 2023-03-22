//
//  Heartbeat.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation
import NIOCore

/// <3
extension Shard {
    func heartbeat(at interval: TimeAmount) {
        Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(interval.nanoseconds))
            } catch {
                self.swiftcord.error("Heartbeat failed to sleep. Error: \(error)")
            }
            
            guard self.isConnected else {
                return
            }

            // TODO: Should 3 missed acks be the determination of a zombied connection? Less?
            guard self.acksMissed < 3 else {
                    self.swiftcord.debug("Did not receive ACK from server, reconnecting...")
                    await self.reconnect()
                return
            }

            self.acksMissed += 1
            self.send(self.heartbeatPayload.encode(), presence: false)
            self.heartbeat(at: interval)
        }
    }
}
