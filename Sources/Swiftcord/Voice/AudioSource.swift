//
//  AudioSource.swift
//  
//
//  Created by Noah Pistilli on 2022-05-10.
//

import Foundation
import NIO

public protocol AudioSource {
    
    /// Reads 20 milliseconds worth of audio.
    /// If the audio is complete, the subclass should return an empty `Data` object.
    /// If `AudioSource.isOpus` is `true`, then then it must return
    /// 20ms worth of Opus encoded audio. Otherwise, it must be 20ms
    /// worth of 16-bit 48KHz stereo PCM, which is about 3,840 bytes
    /// per frame (20ms worth of audio).
    func read() -> Data
    
    /// Whether or not the current audio source is already encoded in opus.
    var isOpus: Bool { get }
}

public class PCMAudio: AudioSource {
    
    /// The audio stream in it's entirety
    var stream: ByteBuffer
        
    public init(stream: Data) {
        self.stream = ByteBuffer(data: stream)
    }
    
    
    public func read() -> Data {
        let ret = self.stream.readData(length: 3840)
        
        if let ret = ret {
            return ret
        }
        
        return Data()
    }
    
    public var isOpus: Bool { false }
}

public class FFmpegPCMAudio: AudioSource {
    
    /// The audio stream in it's entirety
    var stream: ByteBuffer
    
    public init(pathToFile: String) throws {
        
        self.stream = ByteBuffer(data: Data())
    }
    
    public func read() -> Data {
        let ret = self.stream.readData(length: 3840)
        
        if let ret = ret {
            return ret
        }
        
        return Data()
    }
    
    public var isOpus: Bool { false }
}


public class OpusAudio: AudioSource {
    
    /// The audio stream in it's entirety
    var stream: ByteBuffer
        
    var opusStream: [[UInt8]]
    
    var packetPos = -1
        
    public init(stream: Data) {
        self.stream = ByteBuffer(data: stream)
        let packets = OggStream(stream: self.stream).iterPackets()
        self.opusStream = packets
    }
    
    public func read() -> Data {
        packetPos += 1
        
        if packetPos < self.opusStream.count {
            return Data(self.opusStream[packetPos])
        } else {
            return Data()
        }
    }
    
    public var isOpus: Bool { true }
}
