//
//  SlashCommands.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-17.
//

import Foundation

/// Structure that defines a slash command object we send to Discord
public class SlashCommandBuilder: Encodable {
	// Use coding keys so we keep snake-case out of our properties.
	enum CodingKeys: String, CodingKey {
		case defaultMemberPermissions = "default_member_permissions"
		case defaultPermission = "default_permission"
		case description = "description"
		case name = "name"
		case options = "options"
		case type = "type"
	}

    public var name: String
    public var description: String
    public var options: [ApplicationCommandOptions]
    public var defaultMemberPermissions: String?
    public let defaultPermission: Bool // Deprecated soon, should use defaultMemberPermissions going forward.
    public let type: ApplicationType

    public init(name: String, description: String, defaultMemberPermissions: String? = nil) throws {
		guard description.count <= 100 else {
			throw ApplicationCommandSetupError.valueTooLong(errorMsg: "Command '\(name)' description is too long (\(description.count) characters, max is 100).")
		}
		guard name.count <= 32 else {
			throw ApplicationCommandSetupError.valueTooLong(errorMsg: "Command '\(name)' name is too long (\(name.count) characters, max is 32).")
		}

        self.name = name
        self.description = description
        self.options = []
        self.defaultPermission = true
        self.defaultMemberPermissions = defaultMemberPermissions
        self.type = .slashCommand
    }

    public func addOption(option: ApplicationCommandOptions) throws -> Self {
		guard self.options.count < 25 else {
			throw ApplicationCommandSetupError.tooManyElements(errorMsg: "Command '\(self.name)' already has the maximum of 25 options assigned to it. Cannot add option '\(option.name)'.")
		}

        self.options.append(option)
        return self
    }
}
