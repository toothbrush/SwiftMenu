//
//  SwiftMenuUnitTesting.swift
//  SwiftMenuUnitTesting
//
//  Created by paul on 7/10/2022.
//

import XCTest

class SwiftMenuUnitTesting: XCTestCase {

    var passwordList: [String]!

    override func setUpWithError() throws {
        passwordList = [
            "foozoo.com",
            "zoo.com.au",
        ]
    }

    override func tearDownWithError() throws {
        passwordList = nil
    }

    func testEmptyFilterWorks() throws {
        XCTAssert(passwordList.count > 0)
        XCTAssert(PasswordList.filteredEntriesList(filter: "  ", entries: passwordList) == passwordList)
    }

    func testTrivialFilterWorks() throws {
        XCTAssert(PasswordList.filteredEntriesList(filter: "foo", entries: passwordList).contains("foozoo.com"))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            let _ = try! PasswordList.prettyPasswordsList()
        }
    }

}
