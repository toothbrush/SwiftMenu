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
        guard !filter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // If the filter is just whitespace (the initial state), return all
            // (Fun fact, according to String.range in Swift, the empty string is found in no other string!)
            // ((I guess actually that makes sense))
            return entries
        }

        let filterWords = filter // let's say we have a filter like "asdf jkl"
            .split(whereSeparator: { c in c.isWhitespace }) // separate into groups ["asdf", "jkl"] (whitespace is trimmed)
            .map(String.init) // aHA and in Swift we have to actually make Strings explicitly!

        print(filterWords)

        // first see if we can find anything, being strict about the first group matching the start of the string
        let firstTry = entries.filter({ item in
            strictPrefixMatch(filterWords: filterWords, entry: item)
        })

        return firstTry
    }

    static private func strictPrefixMatch(filterWords: [String], entry: String) -> Bool {
        guard filterWords.count > 0 else {
            print("Oh shit, this should never happen!  You passed no filter to this internal function!")
            return false
        }

        let firstWord = filterWords[0]
        var stillMatching = entry.hasPrefix(firstWord)

        if stillMatching {
            // okay, maybe we're in business
            var matchedThusFar : Int = firstWord.count
            for fw in filterWords[1...] {
                let lowerBound = entry.index(entry.startIndex, offsetBy: matchedThusFar)
                let upperBound = entry.endIndex
                let tail = entry[lowerBound..<upperBound]
                if let match = tail.range(of: fw) {
                    matchedThusFar = matchedThusFar + tail.distance(from: tail.startIndex, to: match.upperBound)
                    puts("matchedThusFar = \(matchedThusFar)")
                    // we continue to be in business:
                    // but stillMatching starts true, so we do nothing
                } else {
                    // uh oh, something didn't match.
                    stillMatching = false
                }
            }
        }
        return stillMatching
    }

    static func contentsOfPasswordDirectory() throws -> [String] {
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

    static func prettyPasswordsList() throws -> [String] {
        let raw_files : [String] = try contentsOfPasswordDirectory()

        // Regex replace:  https://developer.apple.com/documentation/foundation/nsregularexpression#//apple_ref/occ/instm/NSRegularExpression/stringByReplacingMatchesInString:options:range:withTemplate:
        let regex = ".*/\\.password-store/(.+)\\.gpg"
        let repl = "$1"

        return raw_files.map { path in
            return path.replacingOccurrences(of: regex, with: repl, options: [.regularExpression])
        }
    }
}
