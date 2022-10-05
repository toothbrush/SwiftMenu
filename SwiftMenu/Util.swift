//
//  Util.swift
//  SwiftMenu
//
//  Created by paul on 4/10/2022.
//

import Foundation

func run_timed(to_time: () -> Void) -> Void {
    // From https://stackoverflow.com/questions/24755558/measure-elapsed-time-in-swift
    print("START Timing")
    let start = DispatchTime.now() // <<<<<<<<<< Start time
    to_time()
    let end = DispatchTime.now()   // <<<<<<<<<<   end time

    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

    print(" END  Time to run: \(timeInterval) seconds")
}
