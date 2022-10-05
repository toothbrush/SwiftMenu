//
//  PDApplication.swift
//  SwiftMenu
//
//  Created by paul on 4/10/2022.
//

import Cocoa

// https://stackoverflow.com/questions/27144113/subclass-nsapplication-in-swift
@objc(PDApplication)
class PDApplication: NSApplication {

    // let's avoid mousey things happening m'kay
    override func sendEvent(_ event: NSEvent) {
        let ignores : [NSEvent.EventType] = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .mouseEntered,
            .mouseExited,
            .scrollWheel,
            .otherMouseDown,
            .otherMouseUp,
            .otherMouseDragged,
            .gesture,
            .magnify,
            .swipe,
            .rotate,
            .beginGesture,
            .endGesture,
            .smartMagnify,
        ]
        if ignores.contains(event.type) {
            return
        }
        super.sendEvent(event)
    }
}
