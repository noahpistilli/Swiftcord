//
//  ShardManager.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import NIOCore
class ShardManager {

    /// The gateway url to connect to
    var gatewayUrl: String?

    /// Array of Shard class
    var shards = [Shard]()
    
    var eventLoopGroup: EventLoopGroup?

    /// Parent Swiftcord class
    weak var swiftcord: Swiftcord?
    
    init(eventLoopGroup: EventLoopGroup?) {
        self.eventLoopGroup = eventLoopGroup
    }

    /**
     Used to create a set amount of shards
     - parameter amount: Number of shards to instantiate
     */
    func create(_ amount: Int) async {
        guard self.swiftcord != nil else { return }
        guard self.shards.isEmpty else { return }

        for id in 0 ..< amount {
            let shard = Shard(self.swiftcord!, id, amount, self.gatewayUrl!, eventLoopGroup: self.eventLoopGroup)
            self.shards.append(shard)
            await shard.start()
        }
    }

    /// Disconnects all shards from the gateway
    func disconnect() {
        guard self.shards.count > 0 else { return }

        for shard in self.shards {
            shard.stop()
        }

        self.shards.removeAll()
    }

    /**
     Kills a specific shard from the gateway
     - parameter id: Id of the shard to kill
     */
    func kill(_ id: Int) {
        guard let index = self.shards.firstIndex(where: { $0.id == id }) else { return }

        let shard = self.shards.remove(at: index)

        shard.stop()
    }

    /**
     Spawns a shard based off id
     - parameter id: Id of shard to spawn
     */
    func spawn(_ id: Int) {
        guard self.swiftcord != nil else { return }
        guard self.shards.first(where: { $0.id == id }) == nil else { return }
        guard self.gatewayUrl != nil else { return }

        let shard = Shard(
            self.swiftcord!,
            id,
            self.swiftcord!.shardCount,
            self.gatewayUrl!,
            eventLoopGroup: self.eventLoopGroup
        )
        self.shards.append(shard)
    }

}
