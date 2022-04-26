//
//  Components.swift
//  Swiftcord
//
//  Created by Noah Pistilli on 2021-12-16.
//

import Foundation

public enum ComponentTypes: Int, Encodable {
    case actionRow = 1, button, selectMenu, textInput
}

public protocol Component: Encodable {
    var type: ComponentTypes { get }
}
