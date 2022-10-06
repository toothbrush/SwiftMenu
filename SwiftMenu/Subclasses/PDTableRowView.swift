//
//  PDTableRowView.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDTableRowView: NSTableRowView {

    // See also:
    // https://stackoverflow.com/questions/9463871/change-selection-color-on-view-based-nstableview
    override func becomeFirstResponder() -> Bool {
        return false
    }

    override func drawBackground(in dirtyRect: NSRect) {
        backgroundColor.set()
        let background = NSBezierPath.init(rect: self.bounds)
        background.fill()
    }

    override func drawSelection(in dirtyRect: NSRect) {
        // draw the selection box, if applicable
        if self.selectionHighlightStyle != .none {
            let selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
            NSColor.blue.setFill()
            NSColor.cyan.setStroke()
            let selectionPath = NSBezierPath.init(rect: selectionRect)
            selectionPath.fill()
            selectionPath.lineWidth = 2
            selectionPath.stroke()
        }
        self.isEmphasized = false
    }
}
