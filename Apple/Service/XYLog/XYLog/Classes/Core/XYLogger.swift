//
//  XYLogger.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogger
public protocol XYLogger {
    func write(data: XYLogData)
}
