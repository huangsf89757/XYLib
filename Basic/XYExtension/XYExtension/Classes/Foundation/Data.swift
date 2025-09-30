//
//  Data.swift
//  MTCgmsKit
//
//  Created by hsf on 2025/8/28.
//

import Foundation

public extension Data {
    /// 转hexString
    func toHexString(separator: String = " ") -> String {
        return map { String(format: "%02X", $0) }.joined(separator: separator)
    }
}
