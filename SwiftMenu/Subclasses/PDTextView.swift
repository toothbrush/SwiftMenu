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

    // we tried to override selectionRange(forProposedRange:granularity) here, and it sort-of worked – shift-arrows were blocked, but cmd-shift-arrow still could select the whole text...  so yeah.  give up on that.
    let customCaretWidth = 3.0

    // https://stackoverflow.com/questions/15647874/custom-insertion-point-for-nstextview
    // https://gist.github.com/koenbok/a1b8d942977f69ff102b
    // https://apple.stackexchange.com/questions/191087/how-to-stop-cursor-blinking-in-pages
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        var rect = rect
        rect.size.width = customCaretWidth

        NSColor.white.set()
        let path = NSBezierPath(rect: rect)
        path.fill()
    }

    override func setNeedsDisplay(_ rect: NSRect, avoidAdditionalLayout flag: Bool) {
        var rect = rect
        rect.size.width += customCaretWidth - 1
        super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
    }

    // Disable autocorrect, e.g., searching for "id.atlassian.com" while you're typing becomes "i'd.atlass..." which sucks, of course.
    // Thanks to https://stackoverflow.com/questions/14866512/nstextview-momentarily-disable-automatic-spelling-correction
    override func handleTextCheckingResults(_ results: [NSTextCheckingResult], forRange range: NSRange, types checkingTypes: NSTextCheckingTypes, options: [NSSpellChecker.OptionKey : Any] = [:], orthography: NSOrthography, wordCount: Int) {
        return
    }
}
