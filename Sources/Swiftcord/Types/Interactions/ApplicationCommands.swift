//
//  ApplicationCommands.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-17.
//

import Foundation

public enum ApplicationType: Int, Codable {
    case slashCommand = 1, userCommand, messageCommand
}

public enum ApplicationCommandType: Int, Codable {
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


/// Existing ApplicationCommands, retrieved with GetApplicationCommands().
/// This does not allow you to change existing commands, but merely inspect them.
/// Localization is untested currently.
public struct ApplicationCommand: Decodable {
	public let id: Snowflake
	public let type: ApplicationCommandType
	public let application_id: Snowflake
	public let guild_id: Snowflake?
	public let name: String
	public let name_localizations: [String:String]?
	public let description: String
	public let description_localizations: [String:String]?
	public let options: [ApplicationCommandOptions]?
	public let default_member_permissions: String?
	public let dm_permission: Bool?
	public let default_permission: Bool?
	public let version: Snowflake
}

/// Options for Application commands
public class ApplicationCommandOptions: Codable {
    public var type: ApplicationCommandType
    public var name: String
    public var description: String
    public var required: Bool?
    public var choices: [ApplicationChoices]?
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
        self.choices!.append(ApplicationChoices(name: name, value: value)) // Force-unwrap since if we're adding choices then this should have been made with init(), not decoded.

        return self
    }

    public func addChoices(choices: ApplicationChoices...) -> Self {
        self.choices! += choices // Force-unwrap since if we're adding choices then this should have been made with init(), not decoded.

        return self
    }

    public func setRequired(required: Bool) -> Self {
        self.required = required

        return self
    }
}

public struct ApplicationChoices: Codable {
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
