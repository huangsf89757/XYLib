//
//  XYLog.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

public final class XYLog {
    public static var enable = false
    public static var logger = XYLogger()
}


public extension XYLog {
    /// 记录日志
    /// - Parameters:
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - id: 唯一id
    ///   - line: 行号
    ///   - level: 级别
    ///   - tag: 标记
    ///   - process: 过程
    ///   - content: 内容
    static func record(file: String = #file,
                       function: String = #function,
                       line: Int = #line,
                       id: String? = nil,
                       level: XYLogLevel = .verbose,
                       tag: [String]? = nil,
                       process: XYLogProcess? = nil,
                       content: Any...) {
        guard enable else {
            return
        }
        // file
        let fileLen = 25
        let fileName = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
        let fileStr = String((fileName + String(repeating: " ", count: fileLen)).prefix(fileLen))
        // function
        let funcLen = 30
        let funcStr = String((function + String(repeating: " ", count: funcLen)).prefix(funcLen))
        // line
        let lineLen = 4
        let lineStr = String(("\(line)" + String(repeating: " ", count: lineLen)).prefix(lineLen))
        // id
        let idLen = 8
        var idStr = String(repeating: " ", count: idLen)
        if let id = id {
            let res = id + idStr
            idStr = String(res.prefix(idLen))
        }
        // level
        let levelStr = level.symbol
        // tag
        var tagStr: String?
        if let tag = tag {
            tagStr = "#\(tag.joined(separator: "."))"
        }
        // process
        let processStr = process?.desc
        // record
        logger.record(file: fileStr,
                      function: funcStr,
                      line: lineStr,
                      id: idStr,
                      level: levelStr,
                      tag: tagStr,
                      process: processStr,
                      content: content)
    }
}

public extension XYLog {
    static func verbose(file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        id: String? = nil,
                        tag: [String]? = nil,
                        process: XYLogProcess? = nil,
                        content: Any...) {
        record(file: file, function: function, line: line, id: id, level: .verbose, tag: tag, process: process, content: content)
    }
    
    static func debug(file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      id: String? = nil,
                      tag: [String]? = nil,
                      process: XYLogProcess? = nil,
                      content: Any...) {
        record(file: file, function: function, line: line, id: id, level: .debug, tag: tag, process: process, content: content)
    }
    
    static func info(file: String = #file,
                     function: String = #function,
                     line: Int = #line,
                     id: String? = nil,
                     tag: [String]? = nil,
                     process: XYLogProcess? = nil,
                     content: Any...) {
        record(file: file, function: function, line: line, id: id, level: .info, tag: tag, process: process, content: content)
    }
    
    static func warning(file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        id: String? = nil,
                        tag: [String]? = nil,
                        process: XYLogProcess? = nil,
                        content: Any...) {
        record(file: file, function: function, line: line, id: id, level: .warning, tag: tag, process: process, content: content)
    }
    
    static func error(file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      id: String? = nil,
                      tag: [String]? = nil,
                      process: XYLogProcess? = nil,
                      content: Any...) {
        record(file: file, function: function, line: line, id: id, level: .error, tag: tag, process: process, content: content)
    }
    
    static func fatal(file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      id: String? = nil,
                      tag: [String]? = nil,
                      process: XYLogProcess? = nil,
                      content: Any...) {
        record(file: file, function: function, line: line, id: id, level: .fatal, tag: tag, process: process, content: content)
    }
}
