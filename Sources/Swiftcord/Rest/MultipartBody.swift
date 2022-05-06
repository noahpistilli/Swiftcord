//
//  MultipartBody.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

#if os(Linux)
import FoundationNetworking
#endif

import Foundation
import MimeType


/// Image Handler
extension Swiftcord {

    /**
     Creates HTTP Body for file uploads

     - parameter payloadJson: JSON body
     - parameter fileData: Array of `AttachmentBuilder` structs
     - parameter boundary: UUID Boundary
     */
    func createMultipartBody(
        with payloadJson: String?,
        fileData: [AttachmentBuilder],
        boundary: String
    ) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n")

        if let payloadJson = payloadJson {
            body.append(
                "Content-Disposition: form-data; name=\"payload_json\"\r\nContent-Type: application/json\r\n\r\n"
            )
            body.append(payloadJson)
            body.append("\r\n")
        }

        for (i, attachment) in fileData.enumerated() {
            let mimetype = MimeType(path: attachment.filename).value
            
            body.append("--\(boundary)\r\n")
            body.append(
                "Content-Disposition: form-data; name=\"files[\(i)]\"; filename=\"\(attachment.filename)\"\r\n"
            )
            body.append("Content-Type: data:\(mimetype)\r\n\r\n")
            body.append(attachment.data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        return body
    }
    
    /**
     Creates HTTP Body for file uploads

     - parameter payloadJson: JSON body
     - parameter fileData: Array of `AttachmentBuilder` structs
     - parameter boundary: UUID Boundary
     */
    func createMultipartBody(
        with payloadJson: Data?,
        fileData: [AttachmentBuilder],
        boundary: String
    )  -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n")

        if let payloadJson = payloadJson {
            body.append(
                "Content-Disposition: form-data; name=\"payload_json\"\r\nContent-Type: application/json\r\n\r\n"
            )
            body.append(payloadJson)
            body.append("\r\n")
        }

        for (i, attachment) in fileData.enumerated() {
            let mimetype = MimeType(path: attachment.filename).value
            
            body.append("--\(boundary)\r\n")
            body.append(
                "Content-Disposition: form-data; name=\"files[\(i)]\"; filename=\"\(attachment.filename)\"\r\n"
            )
            body.append("Content-Type: data:\(mimetype)\r\n\r\n")
            body.append(attachment.data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        return body
    }

}

/// Creates a unique boundary for form data
func createBoundary() -> String {
    return "Boundary-\(UUID().uuidString)"
}

