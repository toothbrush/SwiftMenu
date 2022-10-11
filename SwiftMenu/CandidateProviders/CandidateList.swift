//
//  CandidateList.swift
//  SwiftMenu
//
//  Created by paul on 10/10/2022.
//

import Foundation

protocol CandidateList {
    // You have to implement this in your subclass.
    static func reloadEntries() throws -> [String]
    func retrieveSnippet(for choice: String) -> String?
}

class AbstractCandidateList: CandidateList {
    private var _entries: [String]
    var entries: [String] {
        get {
            return _entries
        }
    }

    init() throws {
        // load candidate list into memory
        _entries = try Self.reloadEntries()
    }

    class func reloadEntries() throws -> [String] {
        fatalError("Implement this in your subclass")
    }

    func retrieveSnippet(for choice: String) -> String? {
        fatalError("Implement this in your subclass")
    }

    func filteredEntriesList(filter: String) -> [String] {
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
            Self.multiwordMatch(filterWords: filterWords, entry: item, mustBePrefix: true)
        })

        // we don't want to miss out on slightly more lax search results though; put them at the end of the list
        let laxResults = entries.filter({ item in
            Self.multiwordMatch(filterWords: filterWords, entry: item, mustBePrefix: false)
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
}
