//
//  PDClipView.swift
//  SwiftMenu
//
//  Created by pauldavid on 19/11/2022.
//

import Cocoa

class PDClipView: NSClipView {
    // Thanks to https://stackoverflow.com/questions/57070733/how-to-scrollrowtovisible-without-animations
    // An attempt to disable scroll animations
    override func scroll(to newOrigin: NSPoint) {
        super.setBoundsOrigin(newOrigin)
    }
}
