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

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            let _ = try! PasswordList.prettyPasswordsList()
        }
    }

}
