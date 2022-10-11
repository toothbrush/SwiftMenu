//
//  ViewController.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import AXSwift
import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var password_table_view: NSTableView!
    @IBOutlet weak var inputField: NSTextField!
    @IBOutlet weak var inputPaddingView: PDColourView!
    @IBOutlet weak var filterCountLabel: NSTextField!

    private var _isReady: Bool = false
    var isReady: Bool {
        get {
            return _isReady
        }
        set {
            _isReady = newValue
            let col = _isReady ? NSColor.systemPurple : NSColor.systemRed
            inputPaddingView.backgroundColor = col
            inputPaddingView.needsDisplay = true
            inputField.backgroundColor = col
            if let cell = inputField.cell as? NSTextFieldCell {
                cell.backgroundColor = col
                cell.controlView?.displayIfNeeded()
            }
            inputField.drawsBackground = true
            inputField.needsDisplay = true
            password_table_view.backgroundColor = col
        }
    }

    var actualPasswordList : [String] = []
    var filteredPasswordList : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        inputField.delegate = self
        NSApp.mainWindow?.makeFirstResponder(inputField)

        password_table_view.delegate = self
        password_table_view.dataSource = self

        filterCountLabel.font = NSFont(name: "MxPlus_IBM_VGA_8x16", size: 16)
        filterCountLabel.textColor = NSColor.lightGray
        filterCountLabel.stringValue = ""

        run_timed {
            // if this fails, probably better to just crash:
            if !self.refreshPasswordListAndTableView() {
                fatalError("Failed to refresh password list.")
            }
        }

        isReady = true
    }

    // For help with custom fonts, see https://troz.net/post/2020/custom-fonts/
    func listInstalledFonts() {
        let fontFamilies = NSFontManager.shared.availableFontFamilies.sorted()
        for family in fontFamilies {
            print(family)
            let familyFonts = NSFontManager.shared.availableMembers(ofFontFamily: family)
            if let fonts = familyFonts {
                for font in fonts {
                    print("\t\(font)")
                }
            }
        }
    }

    func clearFilter() {
        self.inputField.stringValue = ""
        updateTableWithFilter()
    }

    func updateTableWithFilter() {
        let filter = self.inputField.stringValue

        self.filteredPasswordList = PasswordList.filteredEntriesList(filter: filter,
                                                                     entries: self.actualPasswordList)

        self.password_table_view.reloadData()
        self.password_table_view.selectRow(row: 0)
        self.filterCountLabel.stringValue = "\(self.filteredPasswordList.count)/\(self.actualPasswordList.count)"
    }

    static func shared() -> ViewController {
        if let win = NSApp.windows.first {
            if let vc = win.contentViewController as? ViewController {
                return vc
            }
        }
        fatalError("couldn't figure out which instance of ViewController to return!")
    }
}

extension ViewController {
    func showOrHide() {
        if self.view.window!.isVisible,
           self.view.window!.isKeyWindow {
            hideMe()
        } else {
            showMe()
        }
    }
    
    func hideMe() {
        self.view.window!.resignKey() // this appears to be enough to give back focus to the previous app
        self.view.window!.setIsVisible(false)
    }

    func showMe() {
        // Even though this stuff appears to work now, bear in mind that https://stackoverflow.com/questions/17528157/nstextfield-and-firstresponder and https://stackoverflow.com/a/17547777 specifically say you need to
        // [[NSApp mainWindow] resignFirstResponder];
        // (context: "I need to capture this event the NSTextField loses the focus ring to save the uncommitted changes .")
        //
        // See also https://stackoverflow.com/questions/31015568/nssearchfield-occasionally-causing-an-nsinternalinconsistencyexception

        // Pointers
        //
        // I found this stuff via this comment:
        // https://github.com/Hammerspoon/hammerspoon/commit/bfb5a72a6688c4e79e418b7dd7cbe7e7cae80c5c
        // Which comes from
        // https://github.com/Hammerspoon/hammerspoon/pull/2138,
        // but confusingly there's a comment (https://github.com/Hammerspoon/hammerspoon/pull/2138/#issuecomment-523418568) claiming the changes break something.
        // Actually, that's not true (pointed out in https://github.com/Hammerspoon/hammerspoon/pull/1974#issuecomment-523461930 - and when you look closer indeed PR #2138 was never reverted).  Anyway, lots of blind alleys and so on here.
        //
        // https://github.com/Hammerspoon/hammerspoon/issues/2067
        // https://github.com/Hammerspoon/hammerspoon/pull/2062#issuecomment-479764102

        DispatchQueue.global(qos: .default).async {
            let _ = run_timed {
                self.refreshPasswordListAndTableView()
            }
        }

        // i don't know why, but the first time isn't reliable 🤯
        // I suspect if i were smarter about the order of these calls perhaps it'd be more reliable?  But either way this seems to solve the issue i see where on first boot of the app, getting focus is unreliable.  Weird.  But moving on, i have wasted enough of my time on this already.
        for _ in 0...1 {
            self.view.window!.windowController!.showWindow(self.view.window!.windowController!)

            self.view.window?.setIsVisible(true)

            self.view.window!.makeKeyAndOrderFront(self.view.window)
            self.view.window!.makeFirstResponder(self.inputField)

            self.view.window!.styleMask = [.fullSizeContentView, .nonactivatingPanel]

            // This was inspired by (CGWindowLevelForKey(kCGMainMenuWindowLevelKey) + 3) in Hammerspoon, which if you look at the enum definition, is just popupmenu level...
            self.view.window!.level = .popUpMenu
        }

        self.clearFilter()
    }

    // Returns whether it was successful
    func refreshPasswordListAndTableView() -> Bool {
        if let list = try? PasswordList.prettyPasswordsList() {
            self.actualPasswordList = list
            DispatchQueue.main.async {
                self.clearFilter()
            }
            return true
        }
        return false
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredPasswordList.count
    }
}

extension ViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return PDTableRowView()
    }

    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""

        guard let item = filteredPasswordList[safe: row] else {
            return nil
        }

        if tableColumn == tableView.tableColumns[0] {
            text = item
            cellIdentifier = CellIdentifiers.NameCell
        }

        if let ident = tableColumn?.identifier {
            if let cell = tableView.makeView(withIdentifier: ident, owner: self) as? NSTableCellView {
                if ident.rawValue == cellIdentifier {
                    cell.textField?.stringValue = text
                    cell.textField?.font = NSFont(name: "MxPlus_IBM_VGA_8x16", size: 16)
                }
                return cell
            }
            else {
                return nil
            }
        }
        return nil
    }
}

extension ViewController: NSTextFieldDelegate {

    // inspiration: https://stackoverflow.com/questions/47580061/detecting-arrow-enter-keys-when-editing-nstextfield
    // https://stackoverflow.com/questions/29579092/recognize-if-user-has-pressed-arrow-key-while-editing-nstextfield-swift
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector.description == "insertNewline:" {
            if let choice = self.filteredPasswordList[safe: password_table_view.selectedRow] {
                ViewController.shared().hideMe()
                if let pass = PasswordList.retrievePassword(password: choice) {
                    keyStrokes(theString: pass)
                }
            } else {
                print("Selection was empty when you pressed RET")
            }
        } else if commandSelector.description == "cancelOperation:" {
            ViewController.shared().hideMe()
        } else if commandSelector.description == "moveDown:"
                    || commandSelector.description == "moveRight:" {
            password_table_view.selectRow(row: password_table_view.selectedRow + 1)
        } else if commandSelector.description == "moveUp:"
                    || commandSelector.description == "moveLeft:" {
            password_table_view.selectRow(row: password_table_view.selectedRow - 1)
        } else if commandSelector.description == "moveToBeginningOfDocument:"
                    || commandSelector.description == "moveToLeftEndOfLine:" {
            password_table_view.selectRow(row: 0)
        } else if commandSelector.description == "moveToEndOfDocument:"
                    || commandSelector.description == "moveToRightEndOfLine:" {
            password_table_view.selectRow(row: password_table_view.numberOfRows)
        } else if commandSelector.description == "insertTab:" {
            // just eating up tab to reduce likelihood of input box losing focus. sigh.
        } else {
            print("[info] Unhandled NSTextField event \"" + commandSelector.description + "\"")
            return false
        }
        // causes Apple to NOT fire the default enter action
        return true
    }

    func controlTextDidChange(_ obj: Notification) {
        updateTableWithFilter()
    }
}

extension NSTableView {
    func selectRow(row: Int) {
        let row_ = row.clamped(fromInclusive: 0, toInclusive: self.numberOfRows - 1)
        self.scrollRowToVisible(row_)
        self.selectRowIndexes(IndexSet(integer: row_),
                              byExtendingSelection: false)
    }
}
