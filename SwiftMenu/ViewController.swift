//
//  ViewController.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Cocoa
import SwiftHttpServer

class ViewController: NSViewController {

    @IBOutlet weak var password_table_view: NSTableView!
    @IBOutlet weak var inputField: NSTextField!
    @IBOutlet weak var inputPaddingView: PDColourView!

    weak var semaphore: DispatchSemaphore?

    private var _isHandlingRequest: Bool = false
    var isHandlingRequest: Bool {
        get {
            return _isHandlingRequest
        }
        set {
            _isHandlingRequest = newValue
            let col = _isHandlingRequest ? NSColor.systemPurple : NSColor.systemRed
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

    var globalSuccess = false

    let PORT = 22621

    var actualPasswordList : [String] = []
    var filteredPasswordList : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        inputField.delegate = self
        NSApp.mainWindow?.makeFirstResponder(inputField)

        password_table_view.delegate = self
        password_table_view.dataSource = self

        run_timed {
            // if this fails, probably better to just crash:
            if !self.refreshPasswordListAndTableView() {
                fatalError("Failed to refresh password list.")
            }

        }

        let server = HttpServer(hostname: nil, port: PORT, backlog: 6, reusePort: true)
        server.monitor(monitorName: "SwiftMenu-http-server") {
            (name, status, error) in
            if let port = server.listeningPort {
                print(" [\(name ?? "nil") :\(port)] HTTP SERVER Status changed to '\(status)'")
            }
        }

        do {
            try server.route(pattern: "/", handler: LivenessHandler(vc: self))
            try server.route(pattern: "/show", handler: ShowHandler(vc: self))
            try server.route(pattern: "/hide", handler: HideHandler(vc: self))
            try server.route(pattern: "/query_password", handler: PasswordQueryHandler(vc: self))
        } catch let error {
            print(error)
        }

        DispatchQueue.global(qos: .default).async {
            do {
                try server.run()
            } catch let error {
                // This print doesn't work, it's on a background thread.
                print(error)
            }
        }
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
    }
}

extension ViewController {
    func showMe() {
        // Even though this stuff appears to work now, bear in mind that https://stackoverflow.com/questions/17528157/nstextfield-and-firstresponder and https://stackoverflow.com/a/17547777 specifically say you need to
        // [[NSApp mainWindow] resignFirstResponder];
        // (context: "I need to capture this event the NSTextField loses the focus ring to save the uncommitted changes .")
        //
        // See also https://stackoverflow.com/questions/31015568/nssearchfield-occasionally-causing-an-nsinternalinconsistencyexception
        NSApp.mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.clearFilter()
        NSApp.mainWindow?.makeFirstResponder(self.inputField)
        self.password_table_view.selectRow(row: 0)
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
        var iWillEatThisEventDoNotPropagate = false
        globalSuccess = false
        if commandSelector.description == "insertNewline:" {
            iWillEatThisEventDoNotPropagate = true // causes Apple to NOT fire the default enter action

            globalSuccess = true
            // tell a handler, if it's waiting, that we're done!
            if let sem = semaphore {
                sem.signal()
            }
            NSApp.hide(NSApp.mainWindow)
        } else if commandSelector.description == "cancelOperation:" {
            iWillEatThisEventDoNotPropagate = true

            // tell a handler, if it's waiting, that we're done!
            if let sem = semaphore {
                sem.signal()
            }
            NSApp.hide(NSApp.mainWindow)
        } else if commandSelector.description == "moveDown:"
                    || commandSelector.description == "moveRight:" {
            iWillEatThisEventDoNotPropagate = true
            password_table_view.selectRow(row: password_table_view.selectedRow + 1)
        } else if commandSelector.description == "moveUp:"
                    || commandSelector.description == "moveLeft:" {
            iWillEatThisEventDoNotPropagate = true
            password_table_view.selectRow(row: password_table_view.selectedRow - 1)
        } else if commandSelector.description == "moveToBeginningOfDocument:"
                    || commandSelector.description == "moveToLeftEndOfLine:" {
            iWillEatThisEventDoNotPropagate = true
            password_table_view.selectRow(row: 0)
        } else if commandSelector.description == "moveToEndOfDocument:"
                    || commandSelector.description == "moveToRightEndOfLine:" {
            iWillEatThisEventDoNotPropagate = true
            password_table_view.selectRow(row: password_table_view.numberOfRows)
        } else if commandSelector.description == "insertTab:" {
            // just eating up tab to reduce likelihood of input box losing focus. sigh.
            iWillEatThisEventDoNotPropagate = true
        } else {
            print("[info] Unhandled NSTextField event \"" + commandSelector.description + "\"")
        }
        return iWillEatThisEventDoNotPropagate
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
