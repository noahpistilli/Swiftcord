//
//  InteractionEvent.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-18.
//

import Foundation

public protocol InteractionEvent {
    var interactionId: Snowflake { get }
    var swiftcord: Swiftcord { get }
    var token: String { get }
    var ephemeral: Int { get set }
    var isDefered: Bool { get set }
}

public extension InteractionEvent {
    func delete(_ completion: ((RequestError?) -> Void)? = nil) {
        self.swiftcord.requestWithBodyAsData(.deleteWebhook(self.swiftcord.user!.id, self.token)) { data, error in
            if let error = error {
              completion?(error)
            } else {
                completion?(nil)
            }
        }
    }
    
    /// Shows the `Bot is thinking...` text
    mutating func deferReply(_ completion: ((RequestError?) -> Void)? = nil) {
        self.isDefered = true
        
        let body = InteractionResponse(type: .defer, data: InteractionBody<Button>(flags: self.ephemeral))
        
        let jsonData = try! self.swiftcord.encoder.encode(body)

        self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData) { data, error in
            if let error = error {
              completion?(error)
            } else {
                completion?(nil)
            }
        }
    }
    
    func edit(
        message: String,
        then completion: ((Message?, RequestError?) -> Void)? = nil
    ) {
        let body = InteractionBody<Button>(content: message)
            
        let jsonData = try! self.swiftcord.encoder.encode(body)
            
        self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
            if let error = error {
                  completion?(nil, error)
            } else {
                completion?(Message(self.swiftcord, data as! [String: Any]), error)
            }
        }
    }
    
    func editWithButtons(
        buttons: ButtonBuilder,
        then completion: ((Message?, RequestError?) -> Void)? = nil
    ) {
        let body = InteractionBody<Button>(content: buttons.content, embeds: buttons.embeds, components: buttons.components)
        
        let jsonData = try! self.swiftcord.encoder.encode(body)
        
        self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
            if let error = error {
                  completion?(nil, error)
            } else {
                completion?(Message(self.swiftcord, data as! [String: Any]), error)
            }
        }
    }
    
    func editWithEmbeds(
        embeds: EmbedBuilder...,
        then completion: ((Message?, RequestError?) -> Void)? = nil
    ) {
        let body = InteractionBody<Button>(embeds: embeds)
        
        let jsonData = try! self.swiftcord.encoder.encode(body)
        
        self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
            if let error = error {
                  completion?(nil, error)
            } else {
                completion?(Message(self.swiftcord, data as! [String: Any]), error)
            }
        }
    }
    
    func editWithSelectMenu(
        menu: SelectMenuBuilder,
        then completion: ((Message?, RequestError?) -> Void)? = nil
    ) {
        let body = InteractionBody<SelectMenu>(content: menu.content, components: menu.components)
        
        let jsonData = try! self.swiftcord.encoder.encode(body)
        
        self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
            if let error = error {
                  completion?(nil, error)
            } else {
                completion?(Message(self.swiftcord, data as! [String: Any]), error)
            }
        }
    }
    
    /**
     Replies to a slash command interaction
     
     - parameter message: Message to send to the channel
    */
    func reply(
        message: String,
        then completion: ((RequestError?) -> Void)? = nil
    ) {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            // A component will never be passed in this response func, so we place a random Encodable struct.
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<Button>(content: message, flags: self.ephemeral))
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        } else {
            let body = InteractionBody<Button>(content: message)
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    /**
     Replies to a slash command interaction with buttons
     
     - parameter buttons: Buttons to send to the channel
    */
    func replyButtons(
        buttons: ButtonBuilder,
        then completion: ((RequestError?) -> Void)? = nil
    ) {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<Button>(content: buttons.content, flags: self.ephemeral, components: buttons.components))
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        } else {
            let body = InteractionBody<Button>(content: buttons.content, embeds: buttons.embeds, components: buttons.components)
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    /**
     Replies to a slash command interaction with embeds
     
     - parameter buttons: Buttons to send to the channel
    */
    func replyEmbeds(
        embeds: EmbedBuilder...,
        then completion: ((RequestError?) -> Void)? = nil
    ) {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<Button>(flags: self.ephemeral, embeds: embeds))
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        } else {
            let body = InteractionBody<Button>(embeds: embeds)
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    /**
     Replies to a slash command interaction with a select menu
     
     - parameter message: Message to send to the channel
    */
    func replySelectMenu(
        menu: SelectMenuBuilder,
        then completion: ((RequestError?) -> Void)? = nil
    ) {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<SelectMenu>(content: menu.content, flags: self.ephemeral, components: menu.components))
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        } else {
            let body = InteractionBody<SelectMenu>(content: menu.content, components: menu.components)
            
            let jsonData = try! self.swiftcord.encoder.encode(body)
            
            self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData) { data, error in
                if let error = error {
                  completion?(error)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    /// Sets a flag to tell Discord to make the response hidden
    mutating func setEphemeral(isEphermeral: Bool) {
        if isEphermeral {
            self.ephemeral = 64
        } else {
            self.ephemeral = 0
        }
    }
}
