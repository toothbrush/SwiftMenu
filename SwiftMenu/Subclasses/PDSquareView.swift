//
//  PDSquareView.swift
//  SwiftMenu
//
//  Created by paul on 5/10/2022.
//

import Cocoa

class PDSquareView: NSView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // inspiration for this bit:
    // https://developer.apple.com/library/archive/samplecode/RoundTransparentWindow/Listings/Classes_CustomWindow_m.html#//apple_ref/doc/uid/DTS10000401-Classes_CustomWindow_m-DontLinkElementID_8
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.black.set()
        NSRectFromCGRect(self.frame).fill()
    }
}
