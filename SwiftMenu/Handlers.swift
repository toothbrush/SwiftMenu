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
        let success: Bool = run_timed {
            vc.refreshPasswordListAndTableView()
        }
        if !success  {
            throw HttpServerError.operationFailed(string: "Something went wrong listing passwords.")
        }
    }

    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
        response.status = .ok
        response.data = "Raised window\n".data(using: .utf8)

        DispatchQueue.main.async {
            self.vc.showMe()
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
        DispatchQueue.main.async {
            self.vc.isHandlingRequest = true
            self.vc.showMe()
        }

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
        }

        DispatchQueue.main.async {
            NSApp.hide(NSApp.mainWindow)
            self.vc.isHandlingRequest = false
        }

        // return the thing the dialog sent us
        if let pass = passwordResult {
            response.status = .ok
            response.data = pass.data(using: .utf8)
        }
    }
}
