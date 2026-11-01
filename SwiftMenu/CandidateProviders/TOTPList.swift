//
//  TOTPList.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Foundation


class TOTPList: AbstractCandidateList {
    override class func reloadEntries() throws -> [String] {
        var items : [String] = []

        let task = externalCommand("clitotp-go", arguments: ["ls"])

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
            fatalError("Issue listing TOTPs")
        }
        print("Found \(items.count) TOTP entries")

        return items
    }

    override func retrieveSnippet(for choice: String) -> String? {
        guard entries.contains(choice) else {
            return nil
        }

        let task = externalCommand("clitotp-go", arguments: ["generate", choice])

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
            fatalError("Issue retrieving TOTP entry \(choice)")
        }
        return outString
    }
    
    override func wantsAutoReturnKey() -> Bool {
        return true
    }
}
