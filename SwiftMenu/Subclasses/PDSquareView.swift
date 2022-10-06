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

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.set()
        NSRectFromCGRect(self.frame).fill()

        return
    }
}
