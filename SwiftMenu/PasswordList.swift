//
//  PasswordList.swift
//  SwiftMenu
//
//  Created by paul on 2/10/2022.
//

import Foundation

let PATH = NSString("~/.password-store").expandingTildeInPath

extension Sequence where Element: Hashable {
    // i'm a little surprised this works, but i guess that never stopped anyone from ripping things off StackOverflow :/
    // https://stackoverflow.com/questions/25738817/removing-duplicate-elements-from-an-array-in-swift
    // i guess that `set` is being mutated by every call that `filter` makes.. hm. and then reinitialised next time you call uniqued().  I guess that's reasonable.
    // See also https://developer.apple.com/documentation/swift/set/insert(_:)-nads
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}

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

        // first see if we can find anything, being strict about the first group matching the start of the string
        let strictPrefixResults = entries.filter({ item in
            multiwordMatch(filterWords: filterWords, entry: item, mustBePrefix: true)
        })

        // we don't want to miss out on slightly more lax search results though; put them at the end of the list
        let laxResults = entries.filter({ item in
            multiwordMatch(filterWords: filterWords, entry: item, mustBePrefix: false)
        })

        return (strictPrefixResults + laxResults).uniqued()
    }

    static private func multiwordMatch(filterWords: [String], entry: String, mustBePrefix strict: Bool) -> Bool {
        guard filterWords.count > 0 else {
            print("Oh shit, this should never happen!  You passed no filter to this internal function!")
            return false
        }

        var stillMatching: Bool

        if strict {
            // we must stop early if strict = true and the firstWord isn't the prefix of the candidate string.
            stillMatching = entry.hasPrefix(filterWords[0])
        } else {
            // i mean, who knows, but the for loop will find out for us.
            stillMatching = true
        }

        if stillMatching {
            // okay, maybe we're in business. let's start at the beginning though, in case strict=false.
            var matchedThusFar: Int = 0 // the start of `entry`
            for word in filterWords {
                // these bounds are the range within which we'll search for our keyword
                let lowerBound = entry.index(entry.startIndex, offsetBy: matchedThusFar)
                let upperBound = entry.endIndex
                // we want to ignore bits of the string that have matched previous keywords, hence `tail`
                let tail = entry[lowerBound..<upperBound]
                if let match = tail.range(of: word) {
                    matchedThusFar = matchedThusFar + tail.distance(from: tail.startIndex, to: match.upperBound)
                    // we continue to be in business!
                } else {
                    // uh oh, something didn't match.
                    return false
                }
            }
        }
        // the only way we can get here is if stillMatching = true, but hey.
        return stillMatching
    }

    static func contentsOfPasswordDirectory() throws -> [String] {
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

    static func prettyPasswordsList() throws -> [String] {
        let raw_files : [String] = try contentsOfPasswordDirectory()

        // Regex replace:  https://developer.apple.com/documentation/foundation/nsregularexpression#//apple_ref/occ/instm/NSRegularExpression/stringByReplacingMatchesInString:options:range:withTemplate:
        let regex = ".*/\\.password-store/(.+)\\.gpg"
        let repl = "$1"

        return raw_files.map { path in
            return path.replacingOccurrences(of: regex, with: repl, options: [.regularExpression])
        }
    }

    static func retrievePassword(password: String) -> String? {
        let task = Process()
        task.launchPath = "/opt/homebrew/bin/gpg" // let's see if this bites me in the future
        task.arguments = ["--decrypt", "--batch", "\(PATH)/\(password).gpg"]

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
            fatalError("Issue retrieving password entry \(password)")
        }
        return outString
    }
}
