//
//  InteractionResponse.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-18.
//

import Foundation

struct InteractionResponse<T: Component>: Encodable {
    let type: InteractionCallbackType
    let data: InteractionBody<T>?
}

struct InteractionBody<T: Component>: Encodable {
    let content: String?
    let embeds: [EmbedBuilder]?
    let flags: Int?
    let components: [ActionRow<T>]?

    public let customId: String?
    public let title: String?

    init(content: String? = nil, flags: Int? = nil, embeds: [EmbedBuilder]? = nil, components: [ActionRow<T>]? = nil, modal: Modal? = nil) {
        self.content = content
        self.flags = flags
        self.components = components
        self.embeds = embeds
        self.customId = modal?.customId
        self.title = modal?.title
    }
}
