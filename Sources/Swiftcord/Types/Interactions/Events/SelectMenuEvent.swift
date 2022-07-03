//
//  SelectBoxEvent.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-18.
//

import Foundation

public class SelectMenuEvent: InteractionEvent {

    public var channelId: Snowflake

    public let interactionId: Snowflake

    public let swiftcord: Swiftcord

    /// Guild object for this channel
    public var guild: Guild? {
        return self.swiftcord.getGuild(for: channelId)
    }

    public let token: String

    public var member: Member?

    public let user: User

    public let selectedValue: SelectMenuComponentData

    public var ephemeral: Int

    public var isDefered: Bool

    init(_ swiftcord: Swiftcord, data: [String: Any]) {
        self.swiftcord = swiftcord
        self.token = data["token"] as! String

        self.channelId = Snowflake(data["channel_id"])!

        self.interactionId = Snowflake(data["id"] as! String)!

        let inter = data["data"] as! [String: Any]
        let componentData = SelectMenuComponentData(componentType: inter["component_type"] as! Int, customId: inter["custom_id"] as! String, value: (inter["values"] as! [String])[0])
        self.selectedValue = componentData

        var userJson: [String: Any]
        if let memberJson = data["member"] as? [String: Any] {
            userJson = memberJson["user"] as! [String: Any]
        } else {
            userJson = data["user"] as! [String: Any]
        }
        self.user = User(swiftcord, userJson)

        self.ephemeral = 0
        self.isDefered = false

        self.member = nil
        if let memberData = data["member"] as? [String: Any] {
            guard let guild = self.guild else {
                return
            }
            self.member = Member(swiftcord, guild, memberData)
        }
    }
}

public struct SelectMenuComponentData {
    public let componentType: Int
    public let customId: String
    public let value: String
}
