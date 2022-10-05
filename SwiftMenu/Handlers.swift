//
//  Handlers.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Cocoa
import SwiftHttpServer

class LivenessHandler: HttpRequestHandler {
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

        let success: Bool = run_timed {
            vc.refreshPasswordListAndTableView()
        }
        if !success  {
            throw HttpServerError.operationFailed(string: "Something went wrong listing passwords.")
        }
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
            // Even though this stuff appears to work now, bear in mind that https://stackoverflow.com/questions/17528157/nstextfield-and-firstresponder and https://stackoverflow.com/a/17547777 specifically say you need to
            // [[NSApp mainWindow] resignFirstResponder];
            // (context: "I need to capture this event the NSTextField loses the focus ring to save the uncommitted changes .")
            //
            // See also https://stackoverflow.com/questions/31015568/nssearchfield-occasionally-causing-an-nsinternalinconsistencyexception
            NSApp.mainWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.vc.clearFilter()
            NSApp.mainWindow?.makeFirstResponder(self.vc.inputField)
            self.vc.password_table_view.selectRow(row: 0)
        }
    }
}

class HideHandler: HttpRequestHandler {
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
        response.data = "Did hide window\n".data(using: .utf8)

        DispatchQueue.main.async {
            NSApp.hide(NSApp.mainWindow)
        }
    }
}

//TODO superclass which can require POST without code duplication

class PasswordQueryHandler: HttpRequestHandler {
    var dumpBody: Bool = true
    var vc: ViewController

    // Some obscure comments about DispatchSemaphore: https://lists.apple.com/archives/cocoa-dev/2014/Apr/msg00484.html and https://lists.apple.com/archives/cocoa-dev/2014/Apr/msg00483.html
    var semaphore = DispatchSemaphore(value: 0)

    init(vc: ViewController) {
        self.vc = vc
        vc.semaphore = semaphore
        vc.globalSuccess = false
    }

    func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
        if request.method != "POST" {
            throw HttpServerError.illegalArgument(string: "\(request.path) only accepts POST requests.")
        }
    }

    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
        semaphore = DispatchSemaphore(value: 0)
        vc.semaphore = semaphore
        vc.globalSuccess = false

        var passwordResult : String?

        // set a flag "i'm waiting for a password", then actually wait
        let result = semaphore.wait(timeout: .now().advanced(by: .seconds(30)))
        switch result {
        case .success:
            if vc.globalSuccess {
                passwordResult = DispatchQueue.main.sync {
                    vc.filteredPasswordList[safe: vc.password_table_view.selectedRow]
                }
            }
        case .timedOut:
            response.status = .notFound
            response.data = "Timed out asking for password.\n".data(using: .utf8)
            DispatchQueue.main.async {
                NSApp.hide(NSApp.mainWindow)
            }
            return
        }

        // return the thing the dialog sent us
        if let pass = passwordResult {
            response.status = .ok
            response.data = pass.data(using: .utf8)
        }
    }
}
