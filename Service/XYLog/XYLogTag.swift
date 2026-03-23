//
//  XYLogTag.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogTag
public enum XYLogTag {
    case com(contents: [String])
    case tag(contents: [String], throttle: TimeInterval)
}
