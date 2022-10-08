//
//  PasswordList.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Foundation
import PathKit

let PATH = NSString("~/.password-store").expandingTildeInPath

class PasswordList {
    static func filteredEntriesList(filter: String, entries: [String]) -> [String] {
        entries.filter({ item in
            singleEntryMatches(filter: filter, entry: item)
        })
    }

    static func singleEntryMatches(filter: String, entry: String) -> Bool {
        // the empty string is found in no other string!
        guard filter.trimmingCharacters(in: .whitespacesAndNewlines) != "" else { return true }

        return entry.range(of: filter, options: .caseInsensitive) != nil
    }
}

func contentsOfPasswordDirectory() throws -> [String] {
    var items : [String] = []

    print("Password store: \(PATH)")

    let task = Process()
    task.launchPath = "/usr/bin/find" // assuming BSD find - we're on macOS, after all.
    task.arguments = ["-L", "-s", "-x", PATH, "-type", "f", "-iname", "*.gpg"]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        output.enumerateLines { line, stop in
            items.append(line)
        }
    }

    task.waitUntilExit()
    let status = task.terminationStatus
    assert(status == 0)
    print("Found \(items.count) password entries")

    return items
}

func prettyPasswordsList() throws -> [String] {
    let raw_files : [String] = try contentsOfPasswordDirectory()

    // Regex replace:  https://developer.apple.com/documentation/foundation/nsregularexpression#//apple_ref/occ/instm/NSRegularExpression/stringByReplacingMatchesInString:options:range:withTemplate:
    let regex = ".*/\\.password-store/(.+)\\.gpg"
    let repl = "$1"

    return raw_files.map { path in
        return path.replacingOccurrences(of: regex, with: repl, options: [.regularExpression])
    }
}

extension ViewController {
    // Returns whether it was successful
    func refreshPasswordListAndTableView() -> Bool {
        if let list = try? prettyPasswordsList() {
            self.actualPasswordList = list
            DispatchQueue.main.async {
                self.clearFilter()
            }
            return true
        }
        return false
    }
}
