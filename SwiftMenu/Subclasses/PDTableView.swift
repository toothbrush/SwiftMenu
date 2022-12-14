//
//  PDTableView.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Cocoa

class PDTableView: NSTableView {

    // https://stackoverflow.com/questions/24496760/change-the-font-font-color-and-background-color-of-an-nstableview-at-runtime-us
    // https://stackoverflow.com/questions/17095927/dynamically-changing-row-height-after-font-size-of-entire-nstableview-nsoutlin

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.refusesFirstResponder = true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    override func becomeFirstResponder() -> Bool {
        return false
    }
    // Column sizing comments: https://stackoverflow.com/questions/49439311/where-to-set-column-width-in-nstableview-after-updates
    
    // return the number of visible rows
    func nbVisibleRows() -> Int {
        Int(superview!.frame.size.height/rowHeight)
    }
    
    func selectRow(row: Int) {
        let row_ = row.clamped(fromInclusive: 0, toInclusive: self.numberOfRows - 1)
        self.scrollRowToVisible(row_)
        self.selectRowIndexes(IndexSet(integer: row_),
                              byExtendingSelection: false)
    }
}
