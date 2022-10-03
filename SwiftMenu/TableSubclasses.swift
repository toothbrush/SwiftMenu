//
//  TableSubclasses.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class MyNSTableRowView: NSTableRowView {

    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
            NSColor(calibratedWhite: 0.65, alpha: 1).setStroke()
            NSColor(calibratedWhite: 0.82, alpha: 1).setFill()
            let selectionPath = NSBezierPath.init(roundedRect: selectionRect, xRadius: 6, yRadius: 6)
            selectionPath.fill()
            selectionPath.stroke()
        }
        self.isEmphasized = false
        
    }
}
