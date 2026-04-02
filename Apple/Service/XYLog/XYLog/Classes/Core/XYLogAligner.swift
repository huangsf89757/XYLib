//
//  XYLogAligner.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogAligner
public struct XYLogAligner {
    /// 文件名长度
    public var fileLen: Int = 25
    /// 函数名长度
    public var functionLen: Int = 30
    /// 行号长度
    public var lineLen: Int = 4
    /// ID长度
    public var idLen: Int = 8
}

extension XYLogAligner {
    public func align(file: String) -> String {
        let len = self.fileLen
        let space = String(repeating: " ", count: len)
        let name = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
        let str = String((name + space).prefix(len))
        return str
    }
    
    public func align(function: String) -> String {
        let len = self.functionLen
        let space = String(repeating: " ", count: len)
        let str = String((function + space).prefix(len))
        return str
    }
    
    public func align(line: Int) -> String {
        let len = self.lineLen
        let space = String(repeating: " ", count: len)
        let str = String(("\(line)" + space).prefix(len))
        return str
    }
    
    public func align(id: String?) -> String {
        let len = self.idLen
        let space = String(repeating: " ", count: len)
        var str = space
        if let id = id {
            str = String((id + space).prefix(len))
        } else {
            let now = CACurrentMediaTime()
            str = String((space + "\(now)").suffix(len))
        }
        return str
    }
}
