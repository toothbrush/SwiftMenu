//
//  HotKeySolution.swift
//  SwiftMenu
//
//  Created by paul on 30/11/2024.
//

import Carbon
import Cocoa

class HotkeySolution {
    /// See https://stackoverflow.com/questions/28281653/how-to-listen-to-global-hotkeys-with-swift-in-a-macos-app, a Swift translation of venerable global hotkey stuff that works.
    static func getCarbonFlagsFromCocoaFlags(cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
        let flags = cocoaFlags.rawValue
        var newFlags = 0

        if (flags & NSEvent.ModifierFlags.control.rawValue) > 0 {
            newFlags |= controlKey
        }

        if (flags & NSEvent.ModifierFlags.command.rawValue) > 0 {
            newFlags |= cmdKey
        }

        if (flags & NSEvent.ModifierFlags.shift.rawValue) > 0 {
            newFlags |= shiftKey
        }

        if (flags & NSEvent.ModifierFlags.option.rawValue) > 0 {
            newFlags |= optionKey
        }

        if (flags & NSEvent.ModifierFlags.capsLock.rawValue) > 0 {
            newFlags |= alphaLock
        }

        return UInt32(newFlags)
    }

    static func registerHotkeys() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyReleased)

        // Install handler.
        // Want to know what this signature should be?  And the handler lambda??  Well fuck you.  Or look here, https://github.com/davedelong/DDHotKey/blob/e0481f648e0bc7e55d183622b00510b6721152d8/DDHotKeyCenter.m#L19C64-L19C70, because there's no official doc to be found.
        InstallEventHandler(GetApplicationEventTarget(), {
            _, theEvent, _ -> OSStatus in
            var hkCom = EventHotKeyID()

            GetEventParameter(theEvent,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hkCom)

            /// Check that hkCom is indeed our hotkey ID and handle it.
            if hkCom.id == UInt32(kVK_ANSI_P) {
                NSLog("Cmd-Shift-P: toggling password window")
                ViewController.shared().showOrHide(mode: .Password)
            } else if hkCom.id == UInt32(kVK_ANSI_T) {
                NSLog("Opt-Shift-T: toggling TOTP window")
                ViewController.shared().showOrHide(mode: .TOTP)
            } else {
                NSLog("ERROR: Triggered with unbound key: " + hkCom.id.description)
            }

            return noErr
        }, 1, &eventType, nil, nil)

        // Register hotkey.
        registerHotkey(keyCode: kVK_ANSI_P, flags: [NSEvent.ModifierFlags.command, NSEvent.ModifierFlags.shift])
        registerHotkey(keyCode: kVK_ANSI_T, flags: [NSEvent.ModifierFlags.option, NSEvent.ModifierFlags.shift])
    }

    static func registerHotkey(keyCode: Int, flags: NSEvent.ModifierFlags) {
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.id = UInt32(keyCode)
        NSLog("installed hotkey ID: " + gMyHotKeyID.id.description)

        let modifierFlags: UInt32 = getCarbonFlagsFromCocoaFlags(cocoaFlags: flags)

        // Not sure what "swat" vs "htk1" do.
        gMyHotKeyID.signature = OSType("swat".fourCharCodeValue)
        // gMyHotKeyID.signature = OSType("htk1".fourCharCodeValue)

        var hotKeyRef: EventHotKeyRef? // unused
        let status = RegisterEventHotKey(UInt32(keyCode),
                                         modifierFlags,
                                         gMyHotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        assert(status == noErr)
    }
}
