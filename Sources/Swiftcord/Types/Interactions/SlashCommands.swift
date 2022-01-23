//
//  SlashCommands.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-17.
//

import Foundation

/// Structure that defines a slash command object we send to Discord
public class SlashCommandBuilder: Encodable {
    public var name: String
    public var description: String
    public var options: [ApplicationCommandOptions]
    public let defaultPermission: Bool
    public let type: ApplicationType

    public init(name: String, description: String) {
        self.name = name
        self.description = description
        self.options = []
        self.defaultPermission = true
        self.type = .slashCommand
    }

    public func addOption(option: ApplicationCommandOptions) -> Self {
        self.options.append(option)
        return self
    }
}
