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

    let PORT = 3000

    var passwords : [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        passwords = [
            "thies",
            "is",
            "a big test",
        ]
        updatePasswordDisplay()

        password_table_view.delegate = self
        password_table_view.dataSource = self

        let server = HttpServer(hostname: nil, port: PORT, backlog: 6, reusePort: true)
        server.monitor(monitorName: "SwiftMenu-http-server") {
            (name, status, error) in
            if let port = server.listeningPort {
                print(" [\(name ?? "nil") :\(port)] HTTP SERVER Status changed to '\(status)'")
            }
        }

        do {
            try server.route(pattern: "/", handler: HelloHandler(vc: self))
            try server.route(pattern: "/show", handler: ShowHandler(vc: self))
            try server.route(pattern: "/update_password_list", handler: ReloadHandler(vc: self))
        } catch let error {
            print(error)
        }
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            do {
                try server.run()
                print("Visit localhost:\(self.PORT) in your web browser")
            } catch let error {
                print(error)
            }
        }

    }

    func updatePasswordDisplay() {
        password_table_view.reloadData()
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
