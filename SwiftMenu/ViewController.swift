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

    weak var semaphore: DispatchSemaphore?

    var globalSuccess = false

    let PORT = 3000

    var passwords : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        inputField.delegate = self

        password_table_view.delegate = self
        password_table_view.dataSource = self

        // if this fails, probably better to just crash:
        try! self.refreshPasswordListAndTableView()

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
            try server.route(pattern: "/update_password_list", handler: ReloadHandler(vc: self))
            try server.route(pattern: "/query_password", handler: PasswordQueryHandler(vc: self))
        } catch let error {
            print(error)
        }

        DispatchQueue.global(qos: .default).async {
            do {
                try server.run()
                print("Visit localhost:\(self.PORT) in your web browser")
            } catch let error {
                print(error)
            }
        }

    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }


}

extension ViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return passwords.count
    }

}

extension ViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return MyNSTableRowView()
    }

    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""

        guard let item = passwords[safe: row] else {
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
            password_table_view.selectRow(row: passwords.count)
        } else if commandSelector.description == "cancel:" {
            iWillEatThisEventDoNotPropagate = true

            // tell a handler, if it's waiting, that we're done!
            if let sem = semaphore {
                sem.signal()
            }
        } else {
            print("Unhandled NSTextField event \"" + commandSelector.description + "\"")
        }
        return iWillEatThisEventDoNotPropagate
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
