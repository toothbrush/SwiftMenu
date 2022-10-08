//
//  SwiftMenuUnitTesting.swift
//  SwiftMenuUnitTesting
//
//  Created by paul on 7/10/2022.
//

import XCTest

class SwiftMenuUnitTesting: XCTestCase {

    var passwordList: [String]!

    override func setUp() {
        passwordList = [
            "appleid/boo@zonk.com",
            "appleid/frank@example.com",
            "aws-console/rumbleflutes",
            "aws-console/zilch-com",
            "foozoo.com",
            "zoo.com.au",
        ]
    }

    override func tearDown() {
        passwordList = nil
    }

    func testEmptyFilterWorks() {
        XCTAssertGreaterThan(passwordList.count, 0)
        XCTAssertEqual(PasswordList.filteredEntriesList(filter: "  ", entries: passwordList), passwordList)
    }

    func testTrivialFilterWorks() {
        XCTAssert(PasswordList.filteredEntriesList(filter: "foo", entries: passwordList).contains("foozoo.com"))
    }

    func testPrefixPreferred() {
        // we're hoping that given two options, "zoo" and "foozoo", searching for "zoo" will initially match as if you searched for "^zoo", because it's.. closer?  Maybe this will be
        XCTAssertEqual(
            PasswordList.filteredEntriesList(filter: "zoo", entries: passwordList).first!,
            "zoo.com.au")
    }

    func testPrefixNonExclusive() {
        // we're hoping that given two options, "zoo" and "foozoo", searching for "zoo" will initially match as if you searched for "^zoo", because it's.. closer?  Maybe this will be
        XCTAssert(
            PasswordList.filteredEntriesList(filter: "zoo", entries: passwordList).contains("foozoo.com"))
    }

    func testSubstringMatches() {
        XCTAssertGreaterThan(
            PasswordList.filteredEntriesList(filter: "app fr", entries: passwordList).count,
            0)
        XCTAssertEqual(
            PasswordList.filteredEntriesList(filter: "app   fr", entries: passwordList).first,
            "appleid/frank@example.com")
        XCTAssertGreaterThan(
            PasswordList.filteredEntriesList(filter: "app   fr exa", entries: passwordList).count,
            0)
        XCTAssertEqual(
            PasswordList.filteredEntriesList(filter: "app   fr exa", entries: passwordList).first,
            "appleid/frank@example.com")
    }

    func testSubstringOnlyMatchesInOrder() {
        XCTAssertEqual(
            PasswordList.filteredEntriesList(filter: "app   exa    frank", entries: passwordList).count,
            0) // this shouldn't match apple/frank@example, since "example" comes after "frank"
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            let _ = try! PasswordList.prettyPasswordsList()
        }
    }

}
