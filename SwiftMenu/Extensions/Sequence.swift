//
//  Sequence.swift
//  SwiftMenu
//
//  Created by paul on 10/10/2022.
//

import Foundation

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
