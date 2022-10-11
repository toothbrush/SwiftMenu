//
//  SwiftMenuUnitTesting.swift
//  SwiftMenuUnitTesting
//
//  Created by paul on 7/10/2022.
//

import XCTest

let passwordList = [
    "appleid/boo@zonk.com",
    "appleid/frank@example.com",
    "aws-console/rumbleflutes",
    "aws-console/zilch-com",
    "foozoo.com",
    "zoo.com.au",
]

class DummyCandidateList: AbstractCandidateList {
    override class func reloadEntries() throws -> [String] {
        return passwordList
    }
}

class SwiftMenuUnitTesting: XCTestCase {
    var cl: DummyCandidateList!

    override func setUp() {
        cl = try! DummyCandidateList()
    }

    func testEmptyFilterWorks() {
        XCTAssertGreaterThan(cl.entries.count, 0)
        XCTAssertEqual(cl.filteredEntriesList(filter: "  "), passwordList)
    }

    func testTrivialFilterWorks() {
        XCTAssert(cl.filteredEntriesList(filter: "foo").contains("foozoo.com"))
    }

    func testPrefixPreferred() {
        // we're hoping that given two options, "zoo" and "foozoo", searching for "zoo" will initially match as if you searched for "^zoo", because it's.. closer?  Maybe this will be annoying, we'll see
        XCTAssertEqual(
            cl.filteredEntriesList(filter: "zoo").first!,
            "zoo.com.au")
    }

    func testPrefixNonExclusive() {
        // make sure we don't elide valid matches though
        XCTAssert(
            cl.filteredEntriesList(filter: "zoo").contains("foozoo.com"))
    }

    func testSubstringMatches() {
        XCTAssertGreaterThan(
            cl.filteredEntriesList(filter: "app fr").count,
            0)
        XCTAssertEqual(
            cl.filteredEntriesList(filter: "app   fr").first,
            "appleid/frank@example.com")
        XCTAssertGreaterThan(
            cl.filteredEntriesList(filter: "app   fr exa").count,
            0)
        XCTAssertEqual(
            cl.filteredEntriesList(filter: "app   fr exa").first,
            "appleid/frank@example.com")
    }

    func testSubstringOnlyMatchesInOrder() {
        XCTAssertEqual(
            cl.filteredEntriesList(filter: "app   exa    frank").count,
            0) // this shouldn't match apple/frank@example, since "example" comes after "frank"
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        throw XCTSkip("This test is boring and slow.")
        measure {
            let _ = try! PasswordList()
        }
    }

}
