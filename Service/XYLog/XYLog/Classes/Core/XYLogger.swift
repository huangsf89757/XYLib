//
//  XYLogger.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

public protocol XYLogger {
    func record(file: String,
                function: String,
                line: String,
                id: String?,
                level: String,
                tag: String?,
                process: String?,
                content: Any...)
}
