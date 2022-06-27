//
//  AudioSource.swift
//  
//
//  Created by Noah Pistilli on 2022-05-10.
//

import Foundation
import NIO
import SwiftFFmpeg

/// Overarching protocol that all playable types of audio must inherit.
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

/// Class that reads raw PCM s16le audio.
/// PCM must have a sampling rate of 48k and 2 channels.
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

/// Class that converts inputed audio source into PCM playable by Discord using FFmpeg.
public class FFmpegAudio: AudioSource {
    
    /// The audio stream in it's entirety
    var stream: ByteBuffer
    
    // I apologize for the below code. Simply, this function takes any audio format that
    // FFmpeg can demux and filter it into the PCM s16le Discord wants.
    public init(input: String) throws {
        var tempBuffer = Data()
        
        let fmtCtx = try AVFormatContext(url: input)
        try fmtCtx.findStreamInfo()
        
        // Find the type of audio stream
        let streamIndex = fmtCtx.findBestStream(type: .audio)!
        let stream = fmtCtx.streams[streamIndex]
        
        // Create decoder
        let decoder = AVCodec.findDecoderById(stream.codecParameters.codecId)!
        let decoderCtx = AVCodecContext(codec: decoder)
        decoderCtx.setParameters(stream.codecParameters)
        try decoderCtx.openCodec()
        
        let buffersrc = AVFilter(name: "abuffer")!
        let buffersink = AVFilter(name: "abuffersink")!
        let inputs = AVFilterInOut()
        let outputs = AVFilterInOut()
        let sampleFmts = [AVSampleFormat.int16]
        let channelLayouts = [AVChannelLayout.CHL_STEREO]
        let sampleRates = [48000] as [CInt]
        let filterGraph = AVFilterGraph()

        // buffer audio source: the decoded frames from the decoder will be inserted here.
        let args = """
          time_base=\(stream.timebase.num)/\(stream.timebase.den):\
          sample_rate=\(decoderCtx.sampleRate):\
          sample_fmt=\(decoderCtx.sampleFormat.name!):\
          channel_layout=0x\(decoderCtx.channelLayout.rawValue)
          """
        let buffersrcCtx = try filterGraph.addFilter(buffersrc, name: "in", args: args)

        // buffer audio sink: to terminate the filter chain.
        let buffersinkCtx = try filterGraph.addFilter(buffersink, name: "out", args: nil)
        try buffersinkCtx.set(sampleFmts.map({ $0.rawValue }), forKey: "sample_fmts")
        try buffersinkCtx.set(channelLayouts.map({ $0.rawValue }), forKey: "channel_layouts")
        try buffersinkCtx.set(sampleRates, forKey: "sample_rates")

        // Set the endpoints for the filter graph.
        outputs.name = "in"
        outputs.filterContext = buffersrcCtx
        outputs.padIndex = 0
        outputs.next = nil

        // The buffer sink input must be connected to the output pad of
        // the last filter described by filters_descr; since the last
        // filter output label is not specified, it is set to "out" by default.
        inputs.name = "out"
        inputs.filterContext = buffersinkCtx
        inputs.padIndex = 0
        inputs.next = nil

        try filterGraph.parse(
          filters: "aresample=48000,aformat=sample_fmts=s16:channel_layouts=stereo", inputs: inputs,
          outputs: outputs)
        try filterGraph.configure()

        let pkt = AVPacket()
        let frame = AVFrame()
        let filterFrame = AVFrame()

        // Read all packets
        while let _ = try? fmtCtx.readFrame(into: pkt) {
            defer { pkt.unref() }

            if pkt.streamIndex != streamIndex {
                continue
            }

            try decoderCtx.sendPacket(pkt)

            while true {
                do {
                    try decoderCtx.receiveFrame(frame)
                } catch let err as AVError where err == .tryAgain || err == .eof {
                    break
                }

                // push the audio data from decoded frame into the filtergraph
                try buffersrcCtx.addFrame(frame, flags: .keepReference)

                // pull filtered audio from the filtergraph
                while true {
                    do {
                        try buffersinkCtx.getFrame(filterFrame)
                    } catch let err as AVError where err == .tryAgain || err == .eof {
                        break
                    }
              
                    // Now actually write the data
                    let n = filterFrame.sampleCount * filterFrame.channelLayout.channelCount
                    let data = UnsafeRawPointer(filterFrame.data[0]!).bindMemory(to: UInt16.self, capacity: n)
                    
                    for i in 0..<n {
                        tempBuffer.append(UInt8(data[i] & 0xff))
                        tempBuffer.append(UInt8(data[i] >> 8 & 0xff))
                    }
                    
                    filterFrame.unref()
                }
                frame.unref()
            }
        }
        
        self.stream = ByteBuffer(data: tempBuffer)
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

/// Class that plays Opus encoded audio.
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
