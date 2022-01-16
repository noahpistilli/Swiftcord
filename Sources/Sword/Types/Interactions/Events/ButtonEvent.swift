//
//  ButtonEvent.swift
//  Sword
//
//  Created by Noah Pistilli on 2022-01-04.
//

import Foundation

public class ButtonEvent: InteractionEvent {
    
    public var channelId: Snowflake
    
    public let interactionId: Snowflake
    
    public let sword: Sword
    
    /// Guild object for this channel
    public var guild: Guild {
      return self.sword.getGuild(for: channelId)!
    }
    
    public let token: String
    
    public var member: Member?
    
    public let user: User
    
    public let selectedButton: ButtonComponentData
    
    public var ephemeral: Int
    
    public var isDefered: Bool
    
    
    init(_ sword: Sword, data: [String : Any]) {
        self.sword = sword
        self.token = data["token"] as! String
        
        self.channelId = Snowflake(data["channel_id"])!
                
        self.interactionId = Snowflake(data["id"] as! String)!

        let inter = data["data"] as! [String: Any]
        let componentData = ButtonComponentData(componentType: inter["component_type"] as! Int, customId: inter["custom_id"] as! String)
        self.selectedButton = componentData
        
        var userJson = data["member"] as! [String:Any]
        userJson = userJson["user"] as! [String:Any]
        self.user = User(sword, userJson)
        
        self.ephemeral = 0
        self.isDefered = false
        
        self.member = Member(sword, guild, data["member"] as! [String:Any])
    }
}

public struct ButtonComponentData {
    public let componentType: Int
    public let customId: String
}
