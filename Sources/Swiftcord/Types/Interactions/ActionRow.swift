//
//  ActionRow.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-19.
//

import Foundation

/// ActionRow object that can hold any `Component`
public struct ActionRow<T: Component>: Component {
    public let type: ComponentTypes
    public let components: [T]

    enum CodingKeys: String, CodingKey {
        case type
        case components
    }

    public init(components: T...) {
        self.type = .actionRow
        self.components = components
    }

    func encode(from encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.components, forKey: .components)
    }
}
