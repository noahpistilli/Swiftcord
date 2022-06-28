//
//  AudioPlayer.swift
//  
//
//  Created by Noah Pistilli on 2022-05-11.
//

import Foundation

public class AudioPlayer {
    
    public let client: VoiceClient
    
    /// Current state of the audio stream
    private var isDone = false
    
    /// If the audio player is paused or not
    private var isPaused = false

    init(client: VoiceClient) {
        self.client = client
    }
    
    public func play(audioSource: AudioSource) async throws {
        var loops: Int64 = 0
        let start = DispatchTime.now()
        
        let play = self.client.sendAudioPacket
        await self.client.sendSpeaking()

        while !self.isDone {
            // Extremely ugly check for if we are paused but it is what it is
            while self.isPaused {
                try await Task.sleep(seconds: 0.1)
            }

            loops += 1
            let data = audioSource.read()
            
            if data.count == 0 {
                self.isDone.toggle()
            } else {
                try await play(data, audioSource.isOpus)
                
                let nextTime = Int64(start.uptimeNanoseconds) + 20000000 * loops
                let delay = max(0, 20000000 + (nextTime - Int64(DispatchTime.now().uptimeNanoseconds)))
                try await Task.sleep(nanoseconds: UInt64(delay))
            }
        }
    }
    
    public func pause() async {
        self.isPaused = true
        await self.client.sendSpeaking(.none)
    }
    
    public func resume() async {
        self.isPaused = false
        await self.client.sendSpeaking()
    }
    
    public func stop() async {
        self.isDone = true
        await self.client.disconnect()
    }
}
