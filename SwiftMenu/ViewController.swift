//
//  ViewController.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Cocoa
import SwiftHttpServer

class ViewController: NSViewController {

    @IBOutlet weak var text: NSTextField!

    let PORT = 3000

    override func viewDidLoad() {
        super.viewDidLoad()

        var passwords = [
            "thies",
            "is",
            "a big test",
        ]

        text.stringValue = passwords.joined(separator: "\n")
        // Do any additional setup after loading the view.

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


    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }


}

