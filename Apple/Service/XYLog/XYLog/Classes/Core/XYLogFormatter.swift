//
//  XYLogFormatter.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogFormatter
public struct XYLogFormatter {
    /// 级别格式化
    public var levelFormat: String = "[%@]"
    /// 标签格式化
    public var tagFormat: String = "#%@"
    /// 时间间隔格式化
    public var intervalFormat: String = "%.2f"
    /// 进程格式化
    public var processFormat: String = "$%@"
}

extension XYLogFormatter {
    public func format(level: XYLogLevel, style: XYLogStyle) -> String {
        var str = ""
        switch style {
        case .symble:
            str = level.symbol
        case .tag:
            str = level.tag
        }
        return String(format: self.levelFormat, str)
    }
        
    public func format(interval time: TimeInterval?) -> String? {
        if let time {
            let now = CACurrentMediaTime()
            let interval = now - time
            return String(format: self.intervalFormat, interval)
        }
        return nil
    }
    
    public func format(tag: String?) -> String? {
        if let tag {
            return String(format: self.tagFormat, tag)
        }
        return nil
    }
    
    public func format(process: XYLogProcess?, style: XYLogStyle) -> String? {
        if let process = process {
            var str: String
            switch style {
            case .symble:
                str = process.symbol
            case .tag:
                str = process.tag
            }
            return String(format: self.processFormat, str)
        }
        return nil
    }
}
