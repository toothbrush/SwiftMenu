//
//  PDTableView.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDTableView: NSTableView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.refusesFirstResponder = true
    }

    override func becomeFirstResponder() -> Bool {
        return false
    }
    // Column sizing comments: https://stackoverflow.com/questions/49439311/where-to-set-column-width-in-nstableview-after-updates
}
