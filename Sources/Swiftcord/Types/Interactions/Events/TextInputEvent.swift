//
//  TextInputEvent.swift
//  
//
//  Created by Noah Pistilli on 2022-03-07.
//

public class TextInputEvent: InteractionEvent {
    
    public var channelId: Snowflake

    public let interactionId: Snowflake

    public let swiftcord: Swiftcord

    public let token: String

    public var member: Member?

    public var modalID: String
    
    public let user: User

    /// Guild object for this channel
    public var guild: Guild {
        return self.swiftcord.getGuild(for: channelId)!
    }

    public let guildId: Snowflake

    public var ephemeral: Int

    public var isDefered: Bool
    
    public var textInputID: String
    
    public var value: String
    
    init(_ swiftcord: Swiftcord, data: [String: Any]) {
        self.swiftcord = swiftcord
        self.token = data["token"] as! String

        self.channelId = Snowflake(data["channel_id"])!

        self.guildId = Snowflake(data["guild_id"] as! String)!

        var userJson = data["member"] as! [String: Any]
        userJson = userJson["user"] as! [String: Any]
        self.user = User(swiftcord, userJson)

        self.interactionId = Snowflake(data["id"] as! String)!
        let _data = data["data"] as! [String: Any]

        self.ephemeral = 0
        self.isDefered = false
        
        let _textInputData = (_data["components"] as! [Any])[0] as! [String:Any]
        let textInputData = (_textInputData["components"] as! [Any])[0] as! [String:Any]
        
        self.textInputID = textInputData["custom_id"] as! String
        self.value = textInputData["value"] as! String
        
        self.modalID = _data["custom_id"] as! String

        self.member = Member(swiftcord, guild, data["member"] as! [String: Any])
    }
}
