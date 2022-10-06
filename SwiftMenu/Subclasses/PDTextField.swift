//
//  PDTextField.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.function, .numericPad])
        if ["c", "g"].contains(event.charactersIgnoringModifiers), flags == [.control] {
            if let char = event.charactersIgnoringModifiers {
                print("C-\(char): let's cancel.")
            }
            if let delegate = self.delegate as? ViewController {
                delegate.globalSuccess = false
                // tell a handler, if it's waiting, that we're done!
                if let sem = delegate.semaphore {
                    sem.signal()
                }
                NSApp.hide(NSApp.mainWindow)
                return true
            }
        }

        // i guess we're not handling this one!
        return false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        nextResponder = nil
    }

    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }

    // This was far from obvious to me, but these helped:
    // - https://stackoverflow.com/questions/25705232/track-selection-range-change-for-nstextfield-cocoa
    override func becomeFirstResponder() -> Bool {
        let res = super.becomeFirstResponder()

        // https://github.com/onmyway133/blog/issues/588
        // https://stackoverflow.com/questions/25705232/track-selection-range-change-for-nstextfield-cocoa
        if let ed = self.currentEditor() {
            ed.delegate = self
        }

        return res
    }
}

extension PDTextField: NSTextViewDelegate {
    // can we be smart about disallowing range-select?
    // note we needed to do magic to sort out the (ever-changing!) currentEditor's delegate!
    func textView(_ textView: NSTextView,
                  willChangeSelectionFromCharacterRanges oldSelectedCharRanges: [NSValue],
                  toCharacterRanges newSelectedCharRanges: [NSValue]) -> [NSValue] {
        // - https://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        guard newSelectedCharRanges.count == 1 else {
            print("omg wtf, how can you be selecting _multiple_ ranges?")
            return [NSValue(range: NSMakeRange(0, 0))]
        }

        guard let newRange = newSelectedCharRanges.first as? NSRange else {
            print("hm, newSelectedCharRanges is not an NSRange??")
            return [NSValue(range: NSMakeRange(0, 0))]
        }
        guard let oldRange = oldSelectedCharRanges.first as? NSRange else {
            print("hm, oldSelectedCharRanges is not an NSRange??")
            return [NSValue(range: NSMakeRange(0, 0))]
        }

        if newRange.length == 0 {
            // all good, just moving cursor, let the user do whatever
            return newSelectedCharRanges
        } else { // something else - just leave old range's position i guess 🤷
            return [NSValue(range: NSMakeRange(oldRange.location, 0))]
        }
    }
}

