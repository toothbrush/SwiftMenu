//
//  PDWindow.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDWindow: NSWindow {
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return false
    }

    override func becomeFirstResponder() -> Bool {
        return false
    }
}