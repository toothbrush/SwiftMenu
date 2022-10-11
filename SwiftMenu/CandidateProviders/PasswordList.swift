//
//  PasswordList.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Foundation


class PasswordList: AbstractCandidateList {
    private static let PATH = NSString("~/.password-store").expandingTildeInPath

    private static func contentsOfPasswordDirectory() throws -> [String] {
        var items : [String] = []

        print("Password store: \(PATH)")

        let task = Process()
        task.launchPath = "/usr/bin/find" // assuming BSD find - we're on macOS, after all.
        task.arguments = ["-L", "-s", "-x", PATH, "-type", "f", "-iname", "*.gpg"]

        let pipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errPipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            output.enumerateLines { line, stop in
                items.append(line)
            }
        }

        task.waitUntilExit()
        let status = task.terminationStatus
        if status != 0 {
            if let output = String(data: data, encoding: .utf8) {
                print("stdout:")
                print(output)
                print("stderr:")
                print(String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")
                print("status = \(status)")
            }
            fatalError("Issue listing password directory")
        }
        print("Found \(items.count) password entries")

        return items
    }

    override class func reloadEntries() throws -> [String] {
        let raw_files : [String] = try Self.contentsOfPasswordDirectory()

        // Regex replace:  https://developer.apple.com/documentation/foundation/nsregularexpression#//apple_ref/occ/instm/NSRegularExpression/stringByReplacingMatchesInString:options:range:withTemplate:
        let regex = ".*/\\.password-store/(.+)\\.gpg"
        let repl = "$1"

        return raw_files.map { path in
            return path.replacingOccurrences(of: regex, with: repl, options: [.regularExpression])
        }
    }

    override func retrieveSnippet(for choice: String) -> String? {
        let task = Process()
        task.launchPath = "/opt/homebrew/bin/gpg" // let's see if this bites me in the future
        task.arguments = ["--decrypt", "--batch", "\(PasswordList.PATH)/\(choice).gpg"]

        var outString: String?

        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe
        task.launch()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let lines = output.split(whereSeparator: \.isNewline)
            if let first = lines.first {
                outString = String(first)
            }
        }

        task.waitUntilExit()
        let status = task.terminationStatus
        if status != 0 {
            if let output = String(data: data, encoding: .utf8) {
                print("stdout:")
                print(output)
                print("stderr:")
                print(String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "")
                print("status = \(status)")
            }
            fatalError("Issue retrieving password entry \(choice)")
        }
        return outString
    }
}
