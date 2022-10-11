//
//  Util.swift
//  SwiftMenu
//
//  Created by paul on 4/10/2022.
//

import Foundation
import CoreGraphics

func run_timed<T>(to_time: () -> T) -> T {
    // From https://stackoverflow.com/questions/24755558/measure-elapsed-time-in-swift
    print("START Timing")
    let start = DispatchTime.now() // <<<<<<<<<< Start time
    let result = to_time()
    let end = DispatchTime.now()   // <<<<<<<<<<   end time

    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

    print(" END  Time to run: \(timeInterval) seconds")
    return result
}

func keyStrokes(theString: String) {
    let keyDownEvent: CGEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
    let keyUpEvent: CGEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)!

    // This superb implementation was lifted shamelessly from Hammerspoon's libeventtap.m, which has the annotation:
    // This superb implementation was lifted shamelessly from http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg23343.html
    // I did have to convert it to Swift, but the hard work was already done.
    // https://github.com/Hammerspoon/hammerspoon/blob/1bd0c184a6b2acbffad27498b9bb15af3e116b8b/extensions/eventtap/libeventtap.m#L94-L144
    
    let objCString:NSString = NSString(string: theString)

    for charIdx in 0..<objCString.length {
        var char = objCString.character(at: charIdx)
        // Send the keydown
        keyDownEvent.flags = []
        keyDownEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        keyDownEvent.post(tap: CGEventTapLocation.cghidEventTap);

        // Send the keyup
        keyUpEvent.flags = []
        keyUpEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: &char)
        keyUpEvent.post(tap: CGEventTapLocation.cghidEventTap);
    }
}
