//
//  XYLogProcess.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogProcess
public enum XYLogProcess: CaseIterable {
    case begin    // 开始
    case doing    // 过程中
    case succ     // 成功
    case fail     // 失败
    case unknown  // 未知
}

// MARK: - Config
extension XYLogProcess {
    private static var customTags: [XYLogProcess: String] = [:]
    private static var customSymbols: [XYLogProcess: String] = [:]
    private static let configLock = NSLock()
    
    public static func config(level: XYLogProcess, tag: String? = nil, symbol: String? = nil) {
        configLock.lock()
        defer { configLock.unlock() }
        
        if let tag = tag { customTags[level] = tag }
        if let symbol = symbol { customSymbols[level] = symbol }
    }
    
    public static func configBatch(_ configurations: [(level: XYLogProcess, tag: String?, symbol: String?)]) {
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
extension XYLogProcess {
    public var tag: String {
        if let custom = Self.customTags[self] { return custom }
        return defaultTag
    }
    
    private var defaultTag: String {
        switch self {
        case .begin:        return "B"
        case .doing:        return "D"
        case .succ:         return "S"
        case .fail:         return "F"
        case .unknown:      return "U"
        }
    }
}

// MARK: - Symbol
extension XYLogProcess {
    public var symbol: String {
        if let custom = Self.customSymbols[self] { return custom }
        return defaultSymbol
    }
    
    private var defaultSymbol: String {
        switch self {
        case .begin:        return "🔫"
        case .doing:        return "🏃🏻‍➡️"
        case .succ:         return "👏🏻"
        case .fail:         return "🏳️"
        case .unknown:      return "🤷🏻"
        }
    }
}
