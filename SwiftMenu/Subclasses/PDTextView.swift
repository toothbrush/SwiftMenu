//
//  PDTextView.swift
//  SwiftMenu
//
//  Created by paul on 5/10/2022.
//

import Cocoa

class PDTextView: NSTextView {

    // Getting this subclass to work was a bit of a hassle.  Some resources:
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextEditing/Tasks/FieldEditor.html#//apple_ref/doc/uid/20001815-131310
    // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextEditing/Tasks/FieldEditor.html#//apple_ref/doc/uid/20001815-CJBJHGAG
    // https://developers.apple.com/library/archive/documentation/TextFonts/Conceptual/CocoaTextArchitecture/TextEditing/TextEditing.html#//apple_ref/doc/uid/TP40009459-CH3-SW29
    // https://developers.apple.com/library/archive/documentation/Cocoa/Conceptual/TextEditing/Tasks/Subclassing.html#//apple_ref/doc/uid/20000937-CJBJHGAG

    override func selectionRange(forProposedRange proposedCharRange: NSRange,
                                 granularity: NSSelectionGranularity) -> NSRange {

        print("my subclass is called!!!")
        return super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity)
    }

    let customCaretWidth = 3.0

    // https://stackoverflow.com/questions/15647874/custom-insertion-point-for-nstextview
    // https://gist.github.com/koenbok/a1b8d942977f69ff102b
    // https://apple.stackexchange.com/questions/191087/how-to-stop-cursor-blinking-in-pages
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        var rect = rect
        rect.size.width = customCaretWidth

        NSColor.white.set()
        let path = NSBezierPath(roundedRect: rect, xRadius: customCaretWidth / 2, yRadius: customCaretWidth / 2)
        path.fill()
    }

    override func setNeedsDisplay(_ rect: NSRect, avoidAdditionalLayout flag: Bool) {
        var rect = rect
        rect.size.width += customCaretWidth - 1
        super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
    }
}
