//
//  PDColourView.swift
//  SwiftMenu
//
//  Created by paul on 5/10/2022.
//

import Cocoa

class PDColourView: NSView {

    var colour = NSColor.systemRed

    // omg, nsview has no backgroundColor
    // https://stackoverflow.com/questions/2962790/best-way-to-change-the-background-color-for-an-nsview
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        colour.setFill()
        dirtyRect.fill()
    }
}
