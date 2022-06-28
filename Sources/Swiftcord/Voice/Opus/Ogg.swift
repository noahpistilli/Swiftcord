//
//  Ogg.swift
//  
//
//  Created by Noah Pistilli on 2022-05-11.
//

import Foundation
import NIO

class OggPage {
    
    let segNum: Int
    
    let segTable: [UInt8]
    
    let data: [UInt8]
    
    init(stream: inout ByteBuffer) {
        let header = stream.readBytes(length: 23)!
        
        self.segNum = Int(header[22])
        self.segTable = stream.readBytes(length: self.segNum)!
        
        // Uint8 cannot store the amount we need. Cast to int then do our math
        let temp = self.segTable.map {Int($0)}
        let bodyLen = temp.reduce(0, +)
        self.data = stream.readBytes(length: bodyLen)!
    }
    
    func iterPackets() -> Array<Dictionary<[UInt8], Bool>> {
        var packetLen = 0
        var offset = 0
        var partial = true
        
        var returnArray: Array<Dictionary<[UInt8], Bool>> = []
        
        for seg in self.segTable {
            if seg == 255 {
                packetLen += 255
                partial = true
            } else {
                packetLen += Int(seg)
                let byteArray = self.data[offset...offset+packetLen-1].map {$0}
                returnArray.append([byteArray: true])
                offset += packetLen
                packetLen = 0
                partial = false
            }
        }
        
        if partial {
            let byteArray = self.data[offset...].map {$0}
            returnArray.append([byteArray: false])
        }
        
        return returnArray
    }
    
}

class OggStream {
    static let magic: [UInt8] = [0x4F, 0x67, 0x67, 0x53]
    
    var stream: ByteBuffer
    
    init(stream: ByteBuffer) {
        self.stream = stream
    }
    
    private func nextPage() -> OggPage? {
        let magic = self.stream.readBytes(length: 4)
        if let magic = magic {
            if magic == OggStream.magic {
                return OggPage(stream: &self.stream)
            }
        }
        
        return nil
    }
    
    private func iterPages() -> [OggPage] {
        var returnValue = [OggPage]()
        var page = self.nextPage()

        while page != nil {
            returnValue.append(page!)
            page = self.nextPage()
        }
        
        return returnValue
    }
    
    func iterPackets() -> [[UInt8]] {
        var constructedPackets = [[UInt8]]()
        var partial = [UInt8]()
        
        for page in self.iterPages() {
            for data in page.iterPackets() {
                for (bytes, isComplete) in data {
                    partial += bytes
                    
                    if isComplete {
                        constructedPackets.append(partial)
                        partial = [UInt8]()
                    }
                }
            }
        }
        
        return constructedPackets
    }
}
