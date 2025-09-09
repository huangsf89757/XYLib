//
//  XYLogLevel.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

public enum XYLogLevel {
    // debug
    case verbose  // 最详细的日志，通常用于开发调试
    case debug    // 调试信息，用于开发阶段
    // release
    case info     // 普通信息，记录程序正常运行状态
    case warning  // 警告信息，表示可能存在问题但不影响运行
    case error    // 错误信息，表示发生了可恢复的错误
    case fatal    // 致命错误，通常会导致程序终止
    
    public var symbol: String {
        switch self {
        case .verbose:
            return "🔬"
        case .debug:
            return "🧑🏻‍💻"
        case .info:
//            return "🤔"
            return "  "
        case .warning:
            return "😬"
        case .error:
            return "😡"
        case .fatal:
            return "😱"
        }
    }
}
