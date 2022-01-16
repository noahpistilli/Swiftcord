//
//  SlashCommandEvent.swift
//  Sword
//
//  Created by Noah Pistilli on 2021-12-18.
//

import Foundation

public class SlashCommandEvent: InteractionEvent {
    
    public var channelId: Snowflake
    
    private let data: [String : Any]
    
    public let interactionId: Snowflake
    
    public let sword: Sword
    
    public let token: String
    
    /// Guild object for this channel
    public var guild: Guild {
      return self.sword.getGuild(for: channelId)!
    }
        
    public let name: String
    
    public var member: Member?
    
    public let user: User
    
    public var options = [SlashCommandEventOptions]()
    
    public var ephemeral: Int
    
    public var isDefered: Bool
    
    init(_ sword: Sword, data: [String : Any]) {
        // Store the data for later
        self.data = data
        
        let options = data["data"] as! [String:Any]
        
        self.name = options["name"] as! String
        
        for option in options["options"] as! [Any] {
            self.options.append(SlashCommandEventOptions(data: option as! [String:Any]))
        }
        
        self.channelId = Snowflake(data["channel_id"])!
        
        var userJson = data["member"] as! [String:Any]
        userJson = userJson["user"] as! [String:Any]
        self.user = User(sword, userJson)
        
        self.sword = sword
        self.token = data["token"] as! String
                
        self.interactionId = Snowflake(data["id"] as! String)!
        
        self.ephemeral = 0
        self.isDefered = false
                
        self.member = Member(sword, guild, data["member"] as! [String:Any])
    }
    
    /// Returns the option data as a `Bool`.
    public func getOptionAsBool(optionName: String) -> Bool? {
        var bool: Bool? = nil
        
        for option in self.options {
            if option.name == optionName {
                if option.type == .bool {
                    if option.value == "false" {
                        bool = false
                    } else if option.value == "true" {
                        bool = true
                    }
                }
            }
        }
        
        return bool
    }
    
    /// Returns the data from the given option in the Channel protocol. The developer must cast this value to the absolute type.
    public func getOptionAsChannel(optionName: String) -> Channel? {
        let options = self.data["data"] as! [String:Any]
        
        // Options can be nil, as such we return an optional value
        var channel: Channel? = nil
        
        if let optionData = options["resolved"] as! [String:Any]? {
            for option in self.options {
                if option.name == optionName {
                    if option.type == .channel {
                        var channelDict = optionData["channels"] as! [String:Any]
                        channelDict = channelDict[option.value] as! [String:Any]
                        channel = GuildText(self.sword, channelDict)
                    } else {
                        self.sword.warn("The option \(optionName) is not a channel!")
                    }
                    break
                }
            }
        }
        
        return channel
    }
    
    /// Returns the option data as a `Double`. Discord considers this type as a `Number`
    public func getOptionAsDouble(optionName: String) -> Double? {
        var double: Double? = nil
        
        for option in self.options {
            if option.name == optionName {
                if option.type == .number {
                    double = Double(option.value)
                }
            }
        }
        
        return double
    }
    
    /// Returns the option data as an `Int`.
    public func getOptionAsInt(optionName: String) -> Int? {
        var int: Int? = nil
        
        for option in self.options {
            if option.name == optionName {
                if option.type == .int {
                    int = Int(option.value)
                }
            }
        }
        
        return int
    }
    
    /// Returns the option data as `Member` object.
    public func getOptionAsMember(optionName: String) -> Member? {
        let options = self.data["data"] as! [String:Any]
        
        var member: Member? = nil
        
        if let optionData = options["resolved"] as! [String:Any]? {
            for option in self.options {
                if option.name == optionName {
                    if option.type == .user {
                        var memberDict = optionData["members"] as! [String:Any]
                        memberDict = memberDict[option.value] as! [String:Any]
                        member = Member(self.sword, self.sword.getGuild(for: Snowflake(data["channel_id"] as! String)!)!, memberDict)
                        break
                    }
                }
            }
        }
        
        return member
    }
    
    /// Returns the option data as a `Role` object.
    public func getOptionAsRole(optionName: String) -> Role? {
        let options = self.data["data"] as! [String:Any]
        
        // Options can be nil, as such we return an optional value
        var role: Role? = nil
        
        if let optionData = options["resolved"] as! [String:Any]? {
            for option in self.options {
                if option.name == optionName {
                    if option.type == .role {
                        var roleDict = optionData["roles"] as! [String:Any]
                        roleDict = roleDict[option.value] as! [String:Any]
                        role = Role(roleDict)
                    } else {
                        self.sword.warn("The option \(optionName) is not a role!")
                    }
                    break
                }
            }
        }
        
        return role
    }
    
    /// Returns the option data as a `String`.
    public func getOptionAsString(optionName: String) -> String? {        
        var string: String? = nil
        
        for option in self.options {
            if option.name == optionName {
                if option.type == .user {
                    string = option.value
                }
            }
        }
        
        return string
    }
    
    public func getOptionAsUser(optionName: String) -> User? {
        let options = self.data["data"] as! [String:Any]
        
        var user: User? = nil
        
        if let optionData = options["resolved"] as! [String:Any]? {
            for option in self.options {
                if option.name == optionName {
                    if option.type == .user {
                        var userDict = optionData["users"] as! [String:Any]
                        userDict = userDict[option.value] as! [String:Any]
                        user = User(self.sword, userDict)
                        break
                    }
                }
            }
        }
        
        return user
    }
}

public struct SlashCommandEventOptions {
    public let name: String
    public let type: ApplicationCommandType
    public let value: String
    
    init(data: [String:Any]) {
        self.name = data["name"] as! String
        self.type = ApplicationCommandType(rawValue: data["type"] as! Int)!
        
        if self.type == .int {
            self.value = String(data["value"] as! Int)
        }
        else if self.type == .bool {
            self.value = String(data["value"] as! Bool)
        }
        else {
            self.value = data["value"] as! String
        }
    }
}
