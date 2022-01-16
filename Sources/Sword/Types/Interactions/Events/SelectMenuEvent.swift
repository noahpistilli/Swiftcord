//
//  SelectBoxEvent.swift
//  Sword
//
//  Created by Noah Pistilli on 2021-12-18.
//

import Foundation

public class SelectMenuEvent: InteractionEvent {
    
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
    
    public let selectedValue: SelectMenuComponentData
    
    var ephemeral: Int
    
    var isDefered: Bool
    
    
    init(_ sword: Sword, data: [String : Any]) {
        self.sword = sword
        self.token = data["token"] as! String
        
        self.channelId = Snowflake(data["channel_id"])!
                
        self.interactionId = Snowflake(data["id"] as! String)!

        let inter = data["data"] as! [String: Any]
        let componentData = SelectMenuComponentData(componentType: inter["component_type"] as! Int, customId: inter["custom_id"] as! String, value: (inter["values"] as! [String])[0])
        self.selectedValue = componentData
        
        var userJson = data["member"] as! [String:Any]
        userJson = userJson["user"] as! [String:Any]
        self.user = User(sword, userJson)
        
        self.ephemeral = 0
        self.isDefered = false
        
        self.member = Member(sword, guild, data["member"] as! [String:Any])
    }
}

public struct SelectMenuComponentData {
    public let componentType: Int
    public let customId: String
    public let value: String
}
