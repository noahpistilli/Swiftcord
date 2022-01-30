//
//  Button.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-16.
//

import Foundation

public class ButtonBuilder: Encodable {
    /// Message above the buttons. This is required if not sending an embed
    public var content: String?

    /// Embed above the buttons.
    public var embeds: [EmbedBuilder]?

    /// The buttons array
    public var components: [ActionRow<Button>]

    public init(message: String? = nil, embed: EmbedBuilder? = nil) {
        self.content = message
        self.embeds = []

        if let embedBuilder = embed {
            self.embeds?.append(embedBuilder)
        }

        self.components = []
    }

    public func addComponent(component: ActionRow<Button>) -> Self {
        components.append(component)
        return self
    }
}

public enum ButtonStyles: Int, Encodable {
    case blurple = 1, grey, green, red, url
}

public struct Button: Component {
    public let type: ComponentTypes
    public let customId: String
    public let disabled: Bool?
    public let style: ButtonStyles
    public let label: String
    public let emoji: Emoji?
    public let url: String?

    public init(customId: String, disabled: Bool? = false, style: ButtonStyles, label: String, emoji: Emoji? = nil, url: String? = nil) {
        self.type = .button
        self.customId = customId
        self.disabled = disabled
        self.style = style
        self.label = label
        self.emoji = emoji
        self.url = url
    }
}
