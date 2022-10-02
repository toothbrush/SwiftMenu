//
//  ViewController.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var text: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        var passwords = [
            "thies",
            "is",
            "a big test",
        ]

        text.stringValue = passwords.joined(separator: "\n")
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }


}

