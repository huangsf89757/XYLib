//
//  XYLogLevel.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogLevel
public enum XYLogLevel: CaseIterable {
    // debug
    case verbose  // 最详细的日志，通常用于开发调试
    case debug    // 调试信息，用于开发阶段
    // release
    case info     // 普通信息，记录程序正常运行状态
    case warning  // 警告信息，表示可能存在问题但不影响运行
    case error    // 错误信息，表示发生了可恢复的错误
    case fatal    // 致命错误，通常会导致程序终止
}

// MARK: - Config
extension XYLogLevel {
    private static var customTags: [XYLogLevel: String] = [:]
    private static var customSymbols: [XYLogLevel: String] = [:]
    private static let configLock = NSLock()
    
    public static func config(level: XYLogLevel, tag: String? = nil, symbol: String? = nil) {
        configLock.lock()
        defer { configLock.unlock() }
        
        if let tag = tag { customTags[level] = tag }
        if let symbol = symbol { customSymbols[level] = symbol }
    }
    
    public static func configBatch(_ configurations: [(level: XYLogLevel, tag: String?, symbol: String?)]) {
        configLock.lock()
        defer { configLock.unlock() }
        
        for item in configurations {
            if let tag = item.tag { customTags[item.level] = tag }
            if let symbol = item.symbol { customSymbols[item.level] = symbol }
        }
    }
    
    public static func reset() {
        configLock.lock()
        defer { configLock.unlock() }
        customTags.removeAll()
        customSymbols.removeAll()
    }
}

// MARK: - Tag
extension XYLogLevel {
    public var tag: String {
        if let custom = Self.customTags[self] { return custom }
        return defaultTag
    }
    
    private var defaultTag: String {
        switch self {
        case .verbose:      return "V"
        case .debug:        return "D"
        case .info:         return "I"
        case .warning:      return "W"
        case .error:        return "E"
        case .fatal:        return "F"
        }
    }
}

// MARK: - Symbol
extension XYLogLevel {
    public var symbol: String {
        if let custom = Self.customSymbols[self] { return custom }
        return defaultSymbol
    }
    
    private var defaultSymbol: String {
        switch self {
        case .verbose:      return "🔬"
        case .debug:        return "🧑🏻‍💻"
        case .info:         return "🤔"
        case .warning:      return "😬"
        case .error:        return "😡"
        case .fatal:        return "😱"
        }
    }
}
