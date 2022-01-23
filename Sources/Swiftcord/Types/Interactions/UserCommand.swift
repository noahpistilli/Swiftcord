//
//  UserCommand.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-20.
//

import Foundation

/// Structure that defines a user command object we send to Discord
public struct UserCommandBuilder: Encodable {
    public var name: String
    public let defaultPermission: Bool
    public let type: ApplicationType

    public init(name: String) {
        self.name = name
        self.defaultPermission = true
        self.type = .userCommand
    }
}
