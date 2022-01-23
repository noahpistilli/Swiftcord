//
//  UserCommandEvent.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-20.
//

import Foundation

public class UserCommandEvent: InteractionEvent {
    
    public var channelId: Snowflake
    
    public let interactionId: Snowflake
    
    public let name: String
    
    public let swiftcord: Swiftcord
    
    public let token: String
    
    /// Guild object for this channel
    public var guild: Guild {
      return self.swiftcord.getGuild(for: channelId)!
    }
    
    public var member: Member?
    
    public let user: User
    
    public var targetMember: Member?
    
    public let targetUser: User
    
    public let guildId: Snowflake
    
    public var ephemeral: Int
    
    public var isDefered: Bool
    
    init(_ swiftcord: Swiftcord, data: [String : Any]) {
        self.swiftcord = swiftcord
        self.token = data["token"] as! String
        self.guildId = Snowflake(data["guild_id"] as! String)!
        self.channelId = Snowflake(data["channel_id"])!
        
        var userJson = data["member"] as! [String:Any]
        userJson = userJson["user"] as! [String:Any]
        self.user = User(swiftcord, userJson)
                
        self.interactionId = Snowflake(data["id"] as! String)!
        let name = data["data"] as! [String:Any];
        
        self.name = name["name"] as! String
        
        
        self.ephemeral = 0
        self.isDefered = false
        
        let message = data["data"] as! [String:Any]
        let targetId = message["target_id"] as! String
        
        let resolved = message["resolved"] as! [String:Any]
        let userDict = resolved["users"] as! [String:Any]
        
        self.targetUser = User(self.swiftcord, userDict[targetId] as! [String:Any])
    
        self.member = Member(swiftcord, guild, data["member"] as! [String:Any])
    }
}
