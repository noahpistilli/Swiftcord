//
//  VoiceUDP.swift
//  
//
//  Created by Noah Pistilli on 2022-05-10.
//

import Foundation
import NIOCore
import NIOPosix

extension VoiceClient {
    func establishUDPConnection() async {
        self.udpConnection = try! await DatagramBootstrap(group: self.eventLoopGroup)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .bind(to: self.networkingInterface.address!).get()
        
        self.messageHandler.promise = self.eventLoopGroup.next().makePromise(of: Data.self)
        
        try! await self.udpConnection!.pipeline.addHandler(self.messageHandler).get()
    }
    
    func sendToUDPWithDataCallback(data: Data) async -> Data {
        let dest = try! SocketAddress(ipAddress: self.endpointIp, port: self.voicePort)
        
        let buffer = self.udpConnection!.allocator.buffer(data: data)
        let envelope = AddressedEnvelope(remoteAddress: dest, data: buffer)
        
        let _ = try! await self.udpConnection!.writeAndFlush(envelope).get()
        
        return try! await self.messageHandler.promise!.futureResult.get()
    }
    
    func sendToUDP(data: Data) async throws {
        let dest = try SocketAddress(ipAddress: self.endpointIp, port: self.voicePort)
        
        let buffer = self.udpConnection!.allocator.buffer(data: data)
        let envelope = AddressedEnvelope(remoteAddress: dest, data: buffer)
        
        let _ = try await self.udpConnection!.writeAndFlush(envelope).get()
    }
}

class MessageHandler: ChannelInboundHandler {
    public typealias InboundIn = AddressedEnvelope<ByteBuffer>
    
    var promise: EventLoopPromise<Data>?
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if let promise = self.promise {
            // We will always have a response with the first UDP call.
            let inBuff = self.unwrapInboundIn(data)
            promise.succeed(Data(buffer: inBuff.data))
            self.promise = nil
        }
        
        context.write(data, promise: nil)
    }
    
    public func channelReadComplete(context: ChannelHandlerContext) {
        // As we are not really interested getting notified on success or failure we just pass nil as promise to
        // reduce allocations.
        context.flush()
    }
}
