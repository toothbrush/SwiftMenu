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

class ShowHandler: HttpRequestHandler {
    var dumpBody: Bool = true
    var vc: ViewController

    init(vc: ViewController) {
        self.vc = vc
    }

    func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
        if request.method == "POST" {
            puts("header completed: method == \(request.method)")
        } else {
            throw HttpServerError.illegalArgument(string: "\(request.path) only accepts POST requests.")
        }
    }

    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
        puts("body completed")
        response.status = .ok
        response.data = "Hello\n".data(using: .utf8)

        DispatchQueue.main.async {
            NSApp.mainWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
