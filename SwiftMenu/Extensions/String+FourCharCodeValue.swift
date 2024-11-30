//
//  String+FourCharCodeValue.swift
//  SwiftMenu
//
//  Created by paul on 30/11/2024.
//

/// See https://stackoverflow.com/questions/28281653/how-to-listen-to-global-hotkeys-with-swift-in-a-macos-app, a Swift translation of venerable global hotkey stuff that works.

public extension String {
    /// This converts string to UInt as a fourCharCode
    var fourCharCodeValue: Int {
        var result = 0
        if let data = data(using: String.Encoding.macOSRoman) {
            data.withUnsafeBytes { rawBytes in
                let bytes = rawBytes.bindMemory(to: UInt8.self)
                for i in 0 ..< data.count {
                    result = result << 8 + Int(bytes[i])
                }
            }
        }
        return result
    }
}
