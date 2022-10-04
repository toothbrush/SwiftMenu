//
//  AppDelegate.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Cocoa
import SwiftHttpServer


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        // see https://stackoverflow.com/questions/50331083/ui-save-restoration-mechanism-in-cocoa-via-swift
        return false
    }


    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

