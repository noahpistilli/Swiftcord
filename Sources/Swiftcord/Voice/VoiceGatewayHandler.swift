//
//  VoiceGatewayHandler.swift
//  
//
//  Created by Noah Pistilli on 2022-05-09.
//

import Foundation

extension VoiceClient {
    
    func handleVoiceGateway(_ payload: VoicePayload) async {
        guard let op = VoiceOP(rawValue: payload.op) else {

            self.swiftcord.log(
                "Received unknown gateway\nOP: \(payload.op)\nData: \(payload.d)"
            )
            return
        }
        
        switch op {
        case .ready:
            let data = payload.d as! [String:Any]
            
            self.ssrc = data["ssrc"] as! UInt32
            self.voicePort = data["port"] as! Int
            self.endpointIp = data["ip"] as! String
            
            let packet = Data(bytes: [1, 70, self.ssrc], count: 70)
            
            // Establish UDP socket and send IP Discovery
            await self.establishUDPConnection()
            let callback = await self.sendToUDPWithDataCallback(data: packet)
            
            let udpData = [UInt8](callback)
            
            self.ip = String(bytes: udpData[4...udpData[4...].firstIndex(of: 0)! - 1], encoding: .ascii)!
            self.port = Int(udpData[68...].withUnsafeBytes { $0.load(as: UInt16.self) })
            
            self.selectProtocol(ip: self.ip, port: self.port)
            
        case .sessionDescription:
            self.secretKey = (payload.d as! [String:Any])["secret_key"] as! [UInt8]
            await self.sendSpeaking()
            await self.sendSpeaking(.none)
            
            // Now we can dispatch the voice client to our user.
            for listener in self.swiftcord.listenerAdaptors {
                await listener.onVoiceServerUpdate(player: AudioPlayer(client: self))
            }
            
        case .heartbeat:
            self.send(self.heartbeatPayload.encode())

        /// OP: 11
        case .heartbeatACK:
            self.heartbeatQueue.sync { self.acksMissed = 0 }
            
            
        case .hello:
            self.identify()
            self.heartbeat(at: (payload.d as! [String: Any])["heartbeat_interval"] as! Int)
            
        default: return
        }
    }
}
