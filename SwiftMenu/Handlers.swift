//
//  Handlers.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Cocoa
import SwiftHttpServer

class HelloHandler: HttpRequestHandler {
    var dumpBody: Bool = true
    var vc: ViewController

    init(vc: ViewController) {
        self.vc = vc
    }

    func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
        puts("header completed")
    }

    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
        puts("body completed")
        response.status = .ok
        response.data = "Hello\n".data(using: .utf8)
    }
}

class ReloadHandler: HttpRequestHandler {
    var dumpBody: Bool = true
    var vc: ViewController

    init(vc: ViewController) {
        self.vc = vc
    }

    func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
        if request.method != "POST" {
            throw HttpServerError.illegalArgument(string: "\(request.path) only accepts POST requests.")
        }

        let start = DispatchTime.now() // <<<<<<<<<< Start time
        if let passwords = try? prettyPasswordsList() {
            vc.passwords = passwords
            DispatchQueue.main.async {
                self.vc.updatePasswordDisplay()
            }
        } else {
            throw HttpServerError.operationFailed(string: "Something went wrong listing passwords.")
        }
        let end = DispatchTime.now()   // <<<<<<<<<<   end time

        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
        let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

        print("Time to generate password list: \(timeInterval) seconds")


    }

    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
        response.status = .ok
        response.data = "Reloaded database\n".data(using: .utf8)
    }
}


class ShowHandler: HttpRequestHandler {
    var dumpBody: Bool = true
    var vc: ViewController

    init(vc: ViewController) {
        self.vc = vc
    }

    func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
        if request.method != "POST" {
            throw HttpServerError.illegalArgument(string: "\(request.path) only accepts POST requests.")
        }
    }

    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
        response.status = .ok
        response.data = "Raised window\n".data(using: .utf8)

        DispatchQueue.main.async {
            NSApp.mainWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.vc.inputField.stringValue = ""
            NSApp.mainWindow?.resignFirstResponder()
            self.vc.becomeFirstResponder()
            self.vc.inputField.becomeFirstResponder()
            NSApp.mainWindow?.firstResponder?.resignFirstResponder()
            NSApp.mainWindow?.makeFirstResponder(self.vc.inputField)
            self.vc.password_table_view.selectRowIndexes([0], byExtendingSelection: false)
        }
    }
}
