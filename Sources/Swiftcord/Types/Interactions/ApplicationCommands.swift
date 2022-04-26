//
//  ApplicationCommands.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-17.
//

import Foundation

public enum ApplicationType: Int, Encodable {
    case slashCommand = 1, userCommand, messageCommand
}

public enum ApplicationCommandType: Int, Encodable {
    case subCommand = 1, subCommandGroup, string, int, bool, user, channel, role, mentionable, number, attatchment
}

public enum InteractionCallbackType: Int, Encodable {
    case pong = 1
    case sendMessage = 4
    case `defer`
    case deferSilently
    case updateMessage
    case modal = 9
}

/// Options for Application commands
public class ApplicationCommandOptions: Encodable {
    public var type: ApplicationCommandType
    public var name: String
    public var description: String
    public var required: Bool
    public var choices: [ApplicationChoices]
    // TODO: Subcommands
    public var channelTypes: Int?
    public var autoComplete: Bool?

    public init(name: String, description: String, type: ApplicationCommandType) {
        self.type = type
        self.name = name
        self.description = description
        self.required = true
        self.choices = []
        self.channelTypes = nil
        self.autoComplete = false
    }

    public func addChoice(name: String, value: String) -> Self {
        self.choices.append(ApplicationChoices(name: name, value: value))

        return self
    }

    public func addChoices(choices: ApplicationChoices...) -> Self {
        self.choices += choices

        return self
    }

    public func setRequired(required: Bool) -> Self {
        self.required = required

        return self
    }
}

public struct ApplicationChoices: Encodable {
    public let name: String
    public let value: String
}
