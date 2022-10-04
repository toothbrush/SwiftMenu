//
//  PDTableView.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDTableView: NSTableView {
    override func becomeFirstResponder() -> Bool {
        return false
    }
}
