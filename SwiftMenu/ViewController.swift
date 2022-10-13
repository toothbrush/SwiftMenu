//
//  ViewController.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import AXSwift
import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var candidatesTableView: NSTableView!
    @IBOutlet weak var inputField: NSTextField!
    @IBOutlet weak var inputPaddingView: PDColourView!
    @IBOutlet weak var filterCountLabel: NSTextField!

    var _currentMode: Mode = .Password
    var currentMode: Mode {
        get {
            _currentMode
        }
        set {
            _currentMode = newValue
        }
    }

    var candidatesProvider: AbstractCandidateList!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

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
            candidatesTableView.backgroundColor = col
        }
    }

    var filteredEntries : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        inputField.delegate = self
        NSApp.mainWindow?.makeFirstResponder(inputField)

        candidatesTableView.delegate = self
        candidatesTableView.dataSource = self

        filterCountLabel.font = NSFont(name: "MxPlus_IBM_VGA_8x16", size: 16)
        filterCountLabel.textColor = NSColor.lightGray
        filterCountLabel.stringValue = ""

        run_timed {
            // if this fails, probably better to just crash:
            if !self.reloadListAndRefreshTableView() {
                fatalError("Failed to refresh candidates list.")
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

        self.filteredEntries = candidatesProvider.filteredEntriesList(filter: filter)
        let total = candidatesProvider.entries.count

        self.candidatesTableView.reloadData()
        self.candidatesTableView.selectRow(row: 0)
        self.filterCountLabel.stringValue = "\(self.filteredEntries.count)/\(total)"
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

enum Mode {
    case Password
    case TOTP
}

extension ViewController {
    func showOrHide(mode: Mode) {
        if self.view.window!.isVisible,
           self.view.window!.isKeyWindow {
            hideMe()
        } else {
            self.currentMode = mode
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
            run_timed {
                // if this fails, probably better to just crash:
                if !self.reloadListAndRefreshTableView() {
                    fatalError("Failed to refresh candidates list.")
                }
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
    func reloadListAndRefreshTableView() -> Bool {
        do {
            switch currentMode {
            case .Password:
                self.candidatesProvider = try PasswordList()
            case .TOTP:
                self.candidatesProvider = try TOTPList()
            }
        } catch let err {
            print("Issue reloading candidates: \(err)")
            return false
        }
        DispatchQueue.main.async {
            self.clearFilter()
        }
        return true
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredEntries.count
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

        guard let item = filteredEntries[safe: row] else {
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
            if let choice = self.filteredEntries[safe: candidatesTableView.selectedRow] {
                ViewController.shared().hideMe()
                if let snippet = candidatesProvider.retrieveSnippet(for: choice) {
                    keyStrokes(theString: snippet)
                    if candidatesProvider.wantsAutoReturnKey() {
                        sendReturn()
                    }
                }
            } else {
                print("Selection was empty when you pressed RET")
            }
        } else if commandSelector.description == "cancelOperation:" {
            ViewController.shared().hideMe()
        } else if commandSelector.description == "moveDown:"
                    || commandSelector.description == "moveRight:" {
            candidatesTableView.selectRow(row: candidatesTableView.selectedRow + 1)
        } else if commandSelector.description == "moveUp:"
                    || commandSelector.description == "moveLeft:" {
            candidatesTableView.selectRow(row: candidatesTableView.selectedRow - 1)
        } else if commandSelector.description == "moveToBeginningOfDocument:"
                    || commandSelector.description == "moveToLeftEndOfLine:" {
            candidatesTableView.selectRow(row: 0)
        } else if commandSelector.description == "moveToEndOfDocument:"
                    || commandSelector.description == "moveToRightEndOfLine:" {
            candidatesTableView.selectRow(row: candidatesTableView.numberOfRows)
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
