//
//  Task.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
