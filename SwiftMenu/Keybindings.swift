//
//  Keybindings.swift
//  SwiftMenu
//
//  Created by paul on 9/10/2022.
//

import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePasswordDisplay = Self("togglePasswordDisplay", default: Shortcut(.p, modifiers: [.option, .shift]))
    static let toggleTOTPDisplay = Self("toggleTOTPDisplay", default: Shortcut(.t, modifiers: [.option, .shift]))
}
