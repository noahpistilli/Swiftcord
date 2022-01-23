//
//  MessageCommandEvent.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-20.
//

import Foundation

public class MessageCommandEvent: InteractionEvent {
    
    public var channelId: Snowflake
    
    public let interactionId: Snowflake
    
    public let name: String
    
    public let swiftcord: Swiftcord
    
    public let token: String
    
    public var member: Member?
    
    public let user: User
    
    /// Guild object for this channel
    public var guild: Guild {
      return self.swiftcord.getGuild(for: channelId)!
    }
    
    public let guildId: Snowflake
    
    public let message: Message
    
    public var ephemeral: Int
    
    public var isDefered: Bool
    
    init(_ swiftcord: Swiftcord, data: [String : Any]) {
        self.swiftcord = swiftcord
        self.token = data["token"] as! String
        
        self.channelId = Snowflake(data["channel_id"])!
        
        self.guildId = Snowflake(data["guild_id"] as! String)!
        
        var userJson = data["member"] as! [String:Any]
        userJson = userJson["user"] as! [String:Any]
        self.user = User(swiftcord, userJson)
                
        self.interactionId = Snowflake(data["id"] as! String)!
        let name = data["data"] as! [String:Any];
        
        self.name = name["name"] as! String
        
        
        self.ephemeral = 0
        self.isDefered = false
        
        var message = data["data"] as! [String:Any]
        
        let targetId = message["target_id"] as! String
        
        message = message["resolved"] as! [String:Any]
        message =  message["messages"] as! [String:Any]
        message = message[targetId] as! [String:Any]
        
        self.message = Message(swiftcord, message)
        
        self.member = Member(swiftcord, guild, data["member"] as! [String:Any])
    }
}
