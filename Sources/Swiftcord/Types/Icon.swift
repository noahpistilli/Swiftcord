//
//  Icon.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2022-01-18.
//

import Foundation

/// Represents the base64 encoded image needed to send to Discord for Emojis, Stickers, etc...
public struct Icon {
    public let imageType: ImageType
    public let base64Image: String
    
    public init(imageType: ImageType, image: Data) {
        self.imageType = imageType
        self.base64Image = image.base64EncodedString()
    }
    
    func toDataString() -> String {
        return "data:\(self.imageType.rawValue);base64,\(self.base64Image)"
    }
}

public enum ImageType: String {
    case jpeg = "image/jpeg"
    case png = "image/png"
    case webp = "image/webp"
    case gif = "image/gif"
}
