//
//  NullList.swift
//  SwiftMenu
//
//  Created by paul on 12/10/2022.
//

import Foundation

class NullList: AbstractCandidateList {
    override class func reloadEntries() throws -> [String] {
        []
    }

    override func retrieveSnippet(for choice: String) -> String? {
        nil
    }
}
