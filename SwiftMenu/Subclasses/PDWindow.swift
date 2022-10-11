//
//  PDWindow.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDWindow: NSPanel {

    let myFieldEditor = PDTextView()

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        // force NSWindowStyleMaskBorderless, beware:
        // https://developer.apple.com/documentation/appkit/nswindow/stylemask/1644698-borderless
        // "The window displays none of the usual peripheral elements. Useful only for display or caching purposes. A window that uses NSWindowStyleMaskBorderless can’t become key or main, unless the value of canBecomeKey or canBecomeMain is true. Note that you can set a window’s or panel’s style mask to NSWindowStyleMaskBorderless in Interface Builder by deselecting Title Bar in the Appearance section of the Attributes inspector."
        super.init(contentRect: contentRect,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        // sigh https://stackoverflow.com/questions/38986010/when-exactly-does-an-nswindow-get-rounded-corners, https://developer.apple.com/forums/thread/102475
        contentView!.wantsLayer = true
        self.alphaValue = 1.0
        self.isOpaque = false
        assert(self.canBecomeKey)
        assert(self.canBecomeMain)
    }

    override func mouseDown(with event: NSEvent) {
        self.performDrag(with: event)
    }

    // https://stackoverflow.com/questions/33168570/nswindow-resize-indicator-not-visible,
    // updated for Swift:
    // https://github.com/bitsdojo/bitsdojo_window/blob/9b83939c321caa438da4be598f527f028e0efa5f/bitsdojo_window_macos/macos/Classes/BitsdojoWindow.swift
    // we need to override canBecomeKey because "Attempts to make the window the key window are abandoned if the value of this property [canBecomeKey] is false. The value of this property is true if the window has a title bar or a resize bar, or false otherwise.
    // The resize bar disappears when we say that the window's style is borderless.
    // https://developer.apple.com/documentation/appkit/nswindow/1419543-canbecomekey
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

    override func fieldEditor(_ createFlag: Bool, for object: Any?) -> NSText? {
        return myFieldEditor
    }

}
