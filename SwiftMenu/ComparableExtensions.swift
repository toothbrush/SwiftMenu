//
//  ComparableExtensions.swift
//  SwiftMenu
//
//  Created by paul on 3/10/2022.
//

import Foundation

// stolen from https://stackoverflow.com/questions/36110620/standard-way-to-clamp-a-number-between-two-values-in-swift
extension Comparable {
    func clamped(fromInclusive f: Self, toInclusive t: Self) -> Self {
        var v = self
        if v < f { v = f }
        if v > t { v = t }
        // (use SIMPLE, EXPLICIT code here to make it utterly clear
        // whether we are inclusive, what form of equality, etc etc)
        return v
    }
}
