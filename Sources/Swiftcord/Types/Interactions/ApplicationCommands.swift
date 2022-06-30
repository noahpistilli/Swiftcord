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

public enum ApplicationCommandSetupError: Error {
	case tooManyElements(errorMsg: String)
	case valueTooLong(errorMsg: String)
    case invalidOptionType(errorMsg: String)
}

/// Existing ApplicationCommands, retrieved with GetApplicationCommands().
/// This does not allow you to change existing commands, but merely inspect them.
/// Localization is untested currently.
public struct ApplicationCommand: Decodable {
	// Use coding keys so we keep snake-case out of our properties.
	enum CodingKeys: String, CodingKey {
		case applicationId = "application_id"
		case defaultMemberPermissions = "default_member_permissions"
		case defaultPermission = "default_permission"
		case description = "description"
		case dmPermission = "dm_permissions"
		case descriptionLocalizations = "description_localizations"
		case id = "id"
		case guildId = "guild_id"
		case name = "name"
		case nameLocalizations = "name_localizations"
		case options = "options"
		case type = "type"
		case version = "version"
	}

	public let id: Snowflake
	public let type: ApplicationCommandType
	public let applicationId: Snowflake
	public let guildId: Snowflake?
	public let name: String
	public let nameLocalizations: [String: String]?
	public let description: String
	public let descriptionLocalizations: [String: String]?
	public let options: [ApplicationCommandOptions]?
	public let defaultMemberPermissions: String?
	public let dmPermission: Bool?
	public let defaultPermission: Bool?
	public let version: Snowflake
}

/// Options for Application commands
public class ApplicationCommandOptions: Codable {
    public var type: ApplicationCommandType
    public var name: String
    public var description: String
    public var required: Bool?
    public var choices: [ApplicationChoices]?
    public var channelTypes: Int?
    public var autoComplete: Bool?
    public var options: [ApplicationCommandOptions]?

    public init(name: String, description: String, type: ApplicationCommandType) throws {
        guard description.count <= 100 else {
            throw ApplicationCommandSetupError.valueTooLong(errorMsg: "Application Command Option '\(description)' description is too long (\(description.count) characters, max is 100).")
        }
        guard name.count <= 32 else {
            throw ApplicationCommandSetupError.valueTooLong(errorMsg: "Application Command Option '\(name)' name is too long (\(name.count) characters, max is 32).")
        }

        self.type = type
        self.name = name
        self.description = description
        self.required = (type == .subCommandGroup || type == .subCommand) ? nil : true
        self.choices = (type == .subCommandGroup || type == .subCommand) ? nil : []
        self.channelTypes = nil
        self.autoComplete = (type == .subCommandGroup || type == .subCommand) ? nil : false
        self.options = (type == .subCommandGroup || type == .subCommand) ? [] : nil
    }

    public func addChoice(name: String, value: String) throws -> Self {
        guard self.type != .subCommand && self.type != .subCommandGroup else {
            throw ApplicationCommandSetupError.invalidOptionType(errorMsg: "Application Command Option '\(self.name)' is \(self.type) type which does not support choices.")
        }
        
        guard self.choices!.count < 25 else {
            throw ApplicationCommandSetupError.tooManyElements(errorMsg: "Application Command Option '\(self.name)' already has the maximum of 25 choices assigned to it. Cannot add choice '\(name)'.")
        }

        try self.choices!.append(ApplicationChoices(name: name, value: value)) // Force-unwrap since if we're adding choices then this should have been made with init(), not decoded.

        return self
    }

    public func addChoices(choices: ApplicationChoices...) throws -> Self {
        guard self.type != .subCommand && self.type != .subCommandGroup else {
            throw ApplicationCommandSetupError.invalidOptionType(errorMsg: "Application Command Option '\(self.name)' is \(self.type) type which does not support choices.")
        }
        
        guard (self.choices!.count + choices.count) <= 25 else {
            throw ApplicationCommandSetupError.tooManyElements(errorMsg: "Application Command Option '\(self.name)' already has too many choices assigned to it (\(self.choices!.count)) to be able to add \(choices.count) additional ones.")
        }

        self.choices! += choices // Force-unwrap since if we're adding choices then this should have been made with init(), not decoded.

        return self
    }

    public func setRequired(required: Bool) -> Self {
        self.required = required

        return self
    }
    
    public func addOption(option: ApplicationCommandOptions) throws -> Self {
        guard self.options?.count ?? 0 < 25 else {
            throw ApplicationCommandSetupError.tooManyElements(errorMsg: "Command '\(self.name)' already has the maximum of 25 options assigned to it. Cannot add option '\(option.name)'.")
        }
        
        switch self.type {
        case .subCommand where (option.type != .subCommand && option.type != .subCommandGroup):
            self.options == nil ? self.options = [option] : self.options!.append(option)
            
        case .subCommandGroup where option.type == .subCommand:
            self.options == nil ? self.options = [option] : self.options!.append(option)
            
        default:
            throw ApplicationCommandSetupError.invalidOptionType(errorMsg: "Application Command Option '\(self.name)' is not allow to have a \(option.type) type option")
            
        }
        
        return self
    }
}

public struct ApplicationChoices: Codable {
    public let name: String
    public let value: String

    public init(name: String, value: String) throws {
		guard name.count <= 100 else {
			throw ApplicationCommandSetupError.valueTooLong(errorMsg: "Application Choice '\(name)' name is too long (\(name.count) characters, max is 100).")
		}
		guard value.count <= 100 else {
			throw ApplicationCommandSetupError.valueTooLong(errorMsg: "Application Choice '\(name)' value is too long (\(value.count) characters, max is 100).")
		}

        self.name = name
        self.value = value
    }
}
