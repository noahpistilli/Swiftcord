//
//  SelectMenu.swift
//  Sword
//
//  Created by Noah Pistilli on 2021-12-16.
//

import Foundation

public class SelectMenuBuilder: Encodable {
    public var content: String
    public var components: [ActionRow<SelectMenu>]

    public init(message: String) {
        self.content = message
        self.components = []
    }

    public func addComponent(component: ActionRow<SelectMenu>) -> Self {
        components.append(component)
        return self
    }
}


public struct SelectMenu: Component {
    public let type: ComponentTypes
    public let customId: String
    public let options: [SelectMenuOptions]
    public let placeholder: String?
    
    public init(customId: String, placeholder: String? = nil, options: SelectMenuOptions...) {
        self.type = .selectMenu
        self.customId = customId
        self.placeholder = placeholder
        self.options = options
    }
}

public struct SelectMenuOptions: Encodable {
    public let label: String
    public let value: String
    public let description: String?
    public let emoji: Emoji?
    
    public init(label: String, value: String, description: String? = nil, emoji: Emoji? = nil) {
        self.label = label
        self.value = value
        self.description = description
        self.emoji = emoji
    }
}
