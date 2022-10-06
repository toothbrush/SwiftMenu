//
//  PDWindow.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDWindow: NSWindow {

    let myFieldEditor = PDTextView()

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        contentView!.wantsLayer = true
        self.alphaValue = 1.0
        self.isOpaque = false
        assert(self.canBecomeKey)
        assert(self.canBecomeMain)
    }
    
    override public var canBecomeKey: Bool {
        get {
            return true
        }
    }
    override public var canBecomeMain: Bool {
        get {
            return true
        }
    }

    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return false
    }

    override func becomeFirstResponder() -> Bool {
        return false
    }

    override func fieldEditor(_ createFlag: Bool, for object: Any?) -> NSText? {
        return myFieldEditor
    }

}
