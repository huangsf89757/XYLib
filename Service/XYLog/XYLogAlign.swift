//
//  XYLogAlign.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogAlign
public struct XYLogAlign {
    /// 文件名长度
    public var fileLen: Int = 25
    /// 函数名长度
    public var functionLen: Int = 30
    /// 行号长度
    public var lineLen: Int = 4
    /// ID长度
    public var idLen: Int = 8
    /// 级别格式化
    public var levelFormat: String = "[%@]"
    /// 标签格式化
    public var tagFormat: String = "#%@"
    /// 进程格式化
    public var processFormat: String = "$%@"
}

extension XYLogAlign {
    public func format(file: String) -> String {
        let len = self.fileLen
        let space = String(repeating: " ", count: len)
        let name = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
        let str = String((name + space).prefix(len))
        return str
    }
    
    public func format(function: String) -> String {
        let len = self.functionLen
        let space = String(repeating: " ", count: len)
        let str = String((function + space).prefix(len))
        return str
    }
    
    public func format(line: Int) -> String {
        let len = self.lineLen
        let space = String(repeating: " ", count: len)
        let str = String(("\(line)" + space).prefix(len))
        return str
    }
    
    public func format(id: String?) -> String {
        let len = self.idLen
        let space = String(repeating: " ", count: len)
        var str = space
        if let id = id {
            str = String((id + space).prefix(len))
        } else {
            let now = CACurrentMediaTime()
            str = String(("\(now)" + space).suffix(len))
        }
        return str
    }
    
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
