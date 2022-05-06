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
    var attachments: [AttachmentBuilder]?

    public let customId: String?
    public let title: String?

    init(content: String? = nil, flags: Int? = nil, embeds: [EmbedBuilder]? = nil, components: [ActionRow<T>]? = nil, modal: Modal? = nil, attachments: [AttachmentBuilder]? = nil) {
        self.content = content
        self.flags = flags
        self.components = components
        self.embeds = embeds
        self.customId = modal?.customId
        self.title = modal?.title
        self.attachments = attachments
        
        // Fix the attachment builder
        if let attachments = self.attachments {
            for (i, _) in attachments.enumerated() {
                self.attachments![i].id = i
            }
        }
    }
}
