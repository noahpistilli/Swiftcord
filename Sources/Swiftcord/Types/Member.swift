//
//  Member.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation

/// Member Type
public struct Member {

    // MARK: Properties

    /// The member's avatar hash for this guild
    public let avatar: String?

    /// How long the user has left until their timeout finishes
    public let communicationDisabledUntil: Date?

    /// Guild this member is tied to
    public internal(set) weak var guild: Guild?

    /// Whether or not this member is deaf
    public let isDeaf: Bool?

    /// Whether or not this user is muted
    public let isMuted: Bool?

    /// Date when user joined guild
    public let joinedAt: Date?

    /// If the member has passed the guild's Membership Screening
    public let isPending: Bool?

    /// Nickname of member
    public let nick: String?

    /// Permission number for this user
    public internal(set) var permissions: Int = 0

    /// The current status of this user's presence
    public internal(set) var presence: Presence?

    /// How long the member has been boosting the server
    public let premiumSince: Date?

    /// Array of role ids this member has
    public internal(set) var roles = [Role]()

    /// User struct for this member
    public let user: User?

    /// Member's current voice state
    public internal(set) var voiceState: VoiceState?

    // MARK: Initializer

    /**
     Creates a Member struct

     - parameter swiftcord: Parent class to get requester from (and otras properties)
     - parameter json: JSON representable as a dictionary
     */
    init(_ swiftcord: Swiftcord, _ guild: Guild, _ json: [String: Any]) {
        self.guild = guild
        self.avatar = json["avatar"] as? String

        self.communicationDisabledUntil = json["communication_disabled_until"] as? Date

        self.isDeaf = json["deaf"] as? Bool

        let joinedAt = json["joined_at"] as? String
        self.joinedAt = joinedAt?.date

        self.isMuted = json["mute"] as? Bool
        self.isPending = json["pending"] as? Bool
        self.nick = json["nick"] as? String

        let roles = (json["roles"] as! [String]).map({ Snowflake($0)! })
        for role in roles {
            guard let role = guild.roles[role] else { continue }
            self.roles.append(role)
            self.permissions |= role.permissions
        }

        self.premiumSince = json["premium_since"] as? Date

        if let user = json["user"] as? [String: Any] {
            self.user = User(swiftcord, user)
        } else {
            self.user = nil
        }
    }

    // MARK: Functions

    /**
     Checks if member has a certain permission

     - parameter permission: Permission to check for
     */
    public func hasPermission(_ permission: Permission) -> Bool {
        if self.user?.id == self.guild!.ownerId {
            return true
        }

        if self.permissions & Permission.administrator.rawValue > 0 {
            return true
        }

        if self.permissions & permission.rawValue > 0 {
            return true
        }

        return false
    }

}

/// Structure for presences
public struct Presence {
    // MARK: Properties

    /// The current game this user is playing/nil if not playing a game
    public internal(set) var game: String?

    /// The current status for this user
    public internal(set) var status: Status

    // MARK: Initializers

    /// Creates a Presence structure
    init(_ json: [String: Any]) {
        if let game = json["game"] as? [String: Any] {
            self.game = game["name"] as? String
        } else {
            self.game = nil
        }

        self.status = Status(rawValue: json["status"] as! String)!
    }

    /**
     Creates a Presence structure

     - parameter status: Status to set to
     - parameter game: The game name to play
     */
    public init(status: Status = .online, playing game: String? = nil) {
        self.status = status
        self.game = game
    }

}
