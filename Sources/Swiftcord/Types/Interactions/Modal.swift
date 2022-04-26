//
//  Modal.swift
//  
//
//  Created by Noah Pistilli on 2022-03-03.
//

public struct ModalBuilder {
    public let modal: Modal
    public let textInput: TextInput
}

public struct Modal: Encodable {
    public let customId: String
    public let title: String

    public init(customId: String, title: String) {
        self.customId = customId
        self.title = title
    }
}
