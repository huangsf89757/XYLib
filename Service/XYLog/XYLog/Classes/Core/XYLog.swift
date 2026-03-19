//
//  XYLog.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLog
public final class XYLog {
    // MARK: shared
    public static let shared = XYLog()
    private init() { }
    
    // MARK: var
    /// 是否可用
    public var enable = false
    /// 当前日志对象
    public var logger: XYLogger?
    /// 当前日志量
    private var count: Int
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
    private static func record(file: String = #file,
                       function: String = #function,
                       line: Int = #line,
                       id: String? = nil,
                       level: XYLogLevel = .verbose,
                       tag: [String]? = nil,
                       process: XYLogProcess? = nil,
                       content: Any...) {
        guard shared.enable else { return }
        guard let logger = shared.logger else { return }
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
        } else {
            
    //        let count = _counter.wrappingIncrement()
            return String(format: "%llu%06llu", time, count)
        }
        let systemUptime = UInt64(ProcessInfo.processInfo.systemUptime * 1000_000)
        
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
