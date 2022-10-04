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
                return true
            }
        }

        // i guess we're not handling this one!
        return false
    }
}
