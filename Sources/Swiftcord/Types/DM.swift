//
//  DMChannel.swift
//  Swiftcord
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

/// DM Type
public struct DM: TextChannel {

    // MARK: Properties

    /// Parent class
    public internal(set) weak var swiftcord: Swiftcord?

    /// ID of DM
    public let id: Snowflake

    /// The recipient of this DM
    public internal(set) var recipient: User

    /// The last message's ID
    public let lastMessageId: Snowflake?

    /// Indicates what kind of channel this is
    public let type = ChannelType.dm

    // MARK: Initializer

    /**
     Creates a DMChannel struct

     - parameter swiftcord: Parent class
     - parameter json: JSON representable as a dictionary
     */
    init(_ swiftcord: Swiftcord, _ json: [String: Any]) {
        self.swiftcord = swiftcord

        self.id = Snowflake(json["id"])!

        let recipients = json["recipients"] as! [[String: Any]]
        self.recipient = User(swiftcord, recipients[0])

        self.lastMessageId = Snowflake(json["last_message_id"])

        swiftcord.dms[self.recipient.id] = self
    }

}
