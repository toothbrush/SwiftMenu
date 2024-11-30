//
//  AppDelegate.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import AXSwift
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard AXSwift.checkIsProcessTrusted(prompt: true) else {
            print("Not trusted as an AX process; please authorize and re-launch")
            NSApp.terminate(self)
            return
        }

        // we can monkey with user defaults without system-wide `defaults write ..`!
        // https://stackoverflow.com/questions/2076816/how-to-register-user-defaults-using-nsuserdefaults-without-overwriting-existing
        // Unit is millis, it seems.
        // https://apple.stackexchange.com/questions/191087/how-to-stop-cursor-blinking-in-pages
        let blinkDefaults = [
            "NSTextInsertionPointBlinkPeriod": 10000000000000,
            "NSTextInsertionPointBlinkPeriodOn": 10000000000000,
            "NSTextInsertionPointBlinkPeriodOff": 10000000000000,
        ]

        UserDefaults.standard.register(defaults: blinkDefaults)

        // this is roughly how Hammerspoon's chooser initialises itself.  Doesn't seem to help with the thing where focusing a SecureText field breaks my global hotkeys.
        // how does Hammerspoon manage, though?  eventtap?
        //
        // See https://github.com/sindresorhus/KeyboardShortcuts/issues/176, they say Option key is the problem, but i can't raise my window with other bindings, either.
        //
        // let app = NSApplication.shared
        // app.setActivationPolicy(.accessory)
        // app.unhide(nil)
        // app.activate(ignoringOtherApps: true)

        /// See https://stackoverflow.com/questions/28281653/how-to-listen-to-global-hotkeys-with-swift-in-a-macos-app, a Swift translation of venerable global hotkey stuff that works.
        HotkeySolution.registerHotkeys()
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
