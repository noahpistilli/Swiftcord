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
    func delete() async throws {
        _ = try await self.swiftcord.requestWithBodyAsData(.deleteWebhook(self.swiftcord.user!.id, self.token))
    }

    /// Shows the `Bot is thinking...` text
    mutating func deferReply() async throws {
        self.isDefered = true

        let body = InteractionResponse(type: .defer, data: InteractionBody<Button>(flags: self.ephemeral))

        let jsonData = try self.swiftcord.encoder.encode(body)

        _ = try await self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData)
    }

    func edit(
        message: String
    ) async throws -> Message {
        let body = InteractionBody<Button>(content: message)

        let jsonData = try self.swiftcord.encoder.encode(body)

        let data = try await self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData)
        return Message(self.swiftcord, data as! [String: Any])
    }

    func editWithButtons(
        buttons: ButtonBuilder
    ) async throws -> Message {
        let body = InteractionBody<Button>(content: buttons.content, embeds: buttons.embeds, components: buttons.components)

        let jsonData = try self.swiftcord.encoder.encode(body)

        let data = try await self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData)
        return Message(self.swiftcord, data as! [String: Any])
    }

    func editWithEmbeds(
        embeds: EmbedBuilder...
    ) async throws -> Message {
        let body = InteractionBody<Button>(embeds: embeds)

        let jsonData = try self.swiftcord.encoder.encode(body)

        let data = try await self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData)

        return Message(self.swiftcord, data as! [String: Any])
    }

    func editWithSelectMenu(
        menu: SelectMenuBuilder
    ) async throws -> Message {
        let body = InteractionBody<SelectMenu>(content: menu.content, components: menu.components)

        let jsonData = try! self.swiftcord.encoder.encode(body)

        let data = try await self.swiftcord.requestWithBodyAsData(.editWebhook(self.swiftcord.user!.id, self.token), body: jsonData)

        return Message(self.swiftcord, data as! [String: Any])
    }

    /**
     Replies to a slash command interaction

     - parameter message: Message to send to the channel
     */
    func reply(
        message: String
    ) async throws {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            // A component will never be passed in this response func, so we place a random Encodable struct.
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<Button>(content: message, flags: self.ephemeral))

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData)
        } else {
            let body = InteractionBody<Button>(content: message)

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData)
        }
    }
    
    /**
     Replies to a slash command interaction

     - parameter message: Message to send to the channel
     - parameter attachments: Attachment(s) to send to the channel
     */
    func reply(
        message: String,
        attachments: AttachmentBuilder...
    ) async throws {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            // A component will never be passed in this response func, so we place a random Encodable struct.
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<Button>(content: message, flags: self.ephemeral, attachments: attachments))

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData, files: attachments)
        } else {
            let body = InteractionBody<Button>(content: message, attachments: attachments)

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData, files: attachments)
        }
    }

    /**
     Replies to a slash command interaction with buttons

     - parameter buttons: Buttons to send to the channel
     */
    func replyButtons(
        buttons: ButtonBuilder
    ) async throws {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<Button>(content: buttons.content, flags: self.ephemeral, components: buttons.components))

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData)
        } else {
            let body = InteractionBody<Button>(content: buttons.content, embeds: buttons.embeds, components: buttons.components)

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData)
        }
    }

    /**
     Replies to a slash command interaction with embeds

     - parameter buttons: Buttons to send to the channel
     */
    func replyEmbeds(
        embeds: EmbedBuilder...
    ) async throws {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<Button>(flags: self.ephemeral, embeds: embeds))

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData)
        } else {
            let body = InteractionBody<Button>(embeds: embeds)

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData)
        }
    }

    func replyModal(
        modal: ModalBuilder
    ) async throws {
        if !isDefered {
            let body = InteractionResponse(type: .modal, data: InteractionBody<TextInput>(flags: self.ephemeral, components: [ActionRow<TextInput>(components: modal.textInput)], modal: modal.modal))

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData)
        } else {
            let body = InteractionResponse(type: .modal, data: InteractionBody<TextInput>( components: [ActionRow<TextInput>(components: modal.textInput)], modal: modal.modal))

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.interactionId, self.token), body: jsonData)
        }
    }

    /**
     Replies to a slash command interaction with a select menu

     - parameter message: Message to send to the channel
     */
    func replySelectMenu(
        menu: SelectMenuBuilder
    ) async throws {
        // Check if the bot defered the message. Replying to a defered message has an entirely different endpoint
        if !isDefered {
            let body = InteractionResponse(type: .sendMessage, data: InteractionBody<SelectMenu>(content: menu.content, flags: self.ephemeral, components: menu.components))

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToInteraction(self.interactionId, self.token), body: jsonData)
        } else {
            let body = InteractionBody<SelectMenu>(content: menu.content, components: menu.components)

            let jsonData = try! self.swiftcord.encoder.encode(body)

            _ = try await self.swiftcord.requestWithBodyAsData(.replyToDeferedInteraction(self.swiftcord.user!.id, self.token), body: jsonData)
        }
    }

    /// Sets a flag to tell Discord to make the response hidden
    mutating func setEphemeral(_ isEphermeral: Bool) {
        if isEphermeral {
            self.ephemeral = 64
        } else {
            self.ephemeral = 0
        }
    }
}
