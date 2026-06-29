//
//  HotKeySolution.swift
//  SwiftMenu
//
//  Created by paul on 30/11/2024.
//

import Carbon
import Cocoa

class HotkeySolution {
    /// A parsed hotkey: a virtual key code plus Cocoa modifier flags.
    struct KeySpec {
        let keyCode: Int
        let flags: NSEvent.ModifierFlags
    }

    /// Maps the Carbon hotkey ID we assign at registration time back to the action to perform.
    private static var modeByHotkeyID: [UInt32: Mode] = [:]
    private static var nextHotkeyID: UInt32 = 1

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
        let bindings = loadKeyBindings()

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

            /// Look up which action this hotkey ID was bound to.
            if let mode = HotkeySolution.modeByHotkeyID[hkCom.id] {
                NSLog("hotkey \(hkCom.id): toggling \(mode) window")
                ViewController.shared().showOrHide(mode: mode)
            } else {
                NSLog("ERROR: Triggered with unbound key: " + hkCom.id.description)
            }

            return noErr
        }, 1, &eventType, nil, nil)

        for (mode, spec) in bindings {
            registerHotkey(mode: mode, spec: spec)
        }
    }

    static func registerHotkey(mode: Mode, spec: KeySpec) {
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.id = nextHotkeyID
        nextHotkeyID += 1
        modeByHotkeyID[gMyHotKeyID.id] = mode
        NSLog("installing hotkey ID \(gMyHotKeyID.id) for \(mode)")

        let modifierFlags: UInt32 = getCarbonFlagsFromCocoaFlags(cocoaFlags: spec.flags)

        // Not sure what "swat" vs "htk1" do.
        gMyHotKeyID.signature = OSType("swat".fourCharCodeValue)

        var hotKeyRef: EventHotKeyRef? // unused
        let status = RegisterEventHotKey(UInt32(spec.keyCode),
                                         modifierFlags,
                                         gMyHotKeyID,
                                         GetApplicationEventTarget(),
                                         0,
                                         &hotKeyRef)
        if status != noErr {
            fatalError("RegisterEventHotKey failed for \(mode) (keyCode \(spec.keyCode), status \(status)). Is the combination already taken?")
        }
    }

    // MARK: - Configuration

    /// Action name as it appears in the config file -> the Mode it triggers, plus its built-in default binding.
    /// Used both to validate config keys and to supply defaults when the file is absent or omits an action.
    private static let knownActions: [(name: String, mode: Mode, defaultSpec: String)] = [
        ("passmenu", .Password, "cmd-shift-p"),
        ("totpmenu", .TOTP, "cmd-shift-t"),
    ]

    /// Resolve the effective bindings: defaults overlaid with anything in ~/.config/swiftmenu/config.ini.
    private static func loadKeyBindings() -> [(Mode, KeySpec)] {
        let overrides = loadConfigKeybindings()

        let knownNames = Set(knownActions.map { $0.name })
        for name in overrides.keys where !knownNames.contains(name) {
            fatalError("config.ini [keybindings]: unknown action '\(name)'. Known actions: \(knownNames.sorted().joined(separator: ", ")).")
        }

        return knownActions.map { action in
            let raw = overrides[action.name] ?? action.defaultSpec
            return (action.mode, parseKeySpec(raw, action: action.name))
        }
    }

    private static let configPath = ("~/.config/swiftmenu/config.ini" as NSString).expandingTildeInPath

    /// Minimal INI reader. Returns the key/value pairs under [keybindings].
    /// Absent file -> empty (use defaults). Anything malformed -> fatalError, loudly.
    private static func loadConfigKeybindings() -> [String: String] {
        guard FileManager.default.fileExists(atPath: configPath) else { return [:] }

        let contents: String
        do {
            contents = try String(contentsOfFile: configPath, encoding: .utf8)
        } catch {
            fatalError("Failed to read \(configPath): \(error)")
        }

        var result: [String: String] = [:]
        var section = ""
        for (index, rawLine) in contents.components(separatedBy: .newlines).enumerated() {
            let lineNo = index + 1
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix(";") { continue }

            if line.hasPrefix("[") {
                guard line.hasSuffix("]") else {
                    fatalError("\(configPath) line \(lineNo): malformed section header: \(rawLine)")
                }
                section = String(line.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces).lowercased()
                continue
            }

            guard let eq = line.firstIndex(of: "=") else {
                fatalError("\(configPath) line \(lineNo): expected 'key = value', got: \(rawLine)")
            }
            guard section == "keybindings" else {
                fatalError("\(configPath) line \(lineNo): unexpected section '\(section)'. Only [keybindings] is supported.")
            }

            let key = line[..<eq].trimmingCharacters(in: .whitespaces).lowercased()
            var value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            if value.count >= 2, value.hasPrefix("\""), value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            }
            result[key] = value
        }
        return result
    }

    /// Parse e.g. "option-shift-p" into a KeySpec. Separators '-' or '+', case-insensitive.
    /// Everything but the final token is a modifier; the final token is the key.
    private static func parseKeySpec(_ spec: String, action: String) -> KeySpec {
        let tokens = spec.lowercased().split(whereSeparator: { $0 == "-" || $0 == "+" }).map(String.init)
        guard let keyToken = tokens.last else {
            fatalError("config.ini: empty keybinding for '\(action)'.")
        }

        var flags: NSEvent.ModifierFlags = []
        for mod in tokens.dropLast() {
            guard let flag = modifiersByName[mod] else {
                fatalError("config.ini: unknown modifier '\(mod)' in '\(spec)' for '\(action)'. Valid: \(modifiersByName.keys.sorted().joined(separator: ", ")).")
            }
            flags.insert(flag)
        }

        guard let keyCode = keyCodesByName[keyToken] else {
            fatalError("config.ini: unknown key '\(keyToken)' in '\(spec)' for '\(action)'. Use a single letter, digit, or one of: \(keyCodesByName.keys.filter { $0.count > 1 }.sorted().joined(separator: ", ")).")
        }
        return KeySpec(keyCode: keyCode, flags: flags)
    }

    private static let modifiersByName: [String: NSEvent.ModifierFlags] = [
        "cmd": .command, "command": .command,
        "opt": .option, "option": .option, "alt": .option,
        "ctrl": .control, "control": .control,
        "shift": .shift,
    ]

    private static let keyCodesByName: [String: Int] = [
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
        "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
        "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
        "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
        "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
        "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
        "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
        "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
        "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        "space": kVK_Space, "return": kVK_Return, "enter": kVK_Return,
        "tab": kVK_Tab, "escape": kVK_Escape, "esc": kVK_Escape,
        "minus": kVK_ANSI_Minus, "equal": kVK_ANSI_Equal,
        "comma": kVK_ANSI_Comma, "period": kVK_ANSI_Period, "slash": kVK_ANSI_Slash,
    ]
}
