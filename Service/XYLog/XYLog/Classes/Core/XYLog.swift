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
    /// 使用样式
    private var style: Style = .symble
    public enum Style {
        case symble
        case tag
    }
    
    // MARK: func
    public static func config(enable: Bool = true, style: Style = .tag, logger: XYLogger) {
        shared.enable = enable
        shared.style = style
        shared.logger = logger
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
        let fileSpace = String(repeating: " ", count: fileLen)
        let fileName = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
        let fileStr = String((fileName + fileSpace).prefix(fileLen))
        
        // function
        let funcLen = 30
        let funcSpace = String(repeating: " ", count: funcLen)
        let funcStr = String((function + funcSpace).prefix(funcLen))
        
        // line
        let lineLen = 4
        let lineSpace = String(repeating: " ", count: lineLen)
        let lineStr = String(("\(line)" + lineSpace).prefix(lineLen))
        
        // id
        let idLen = 8
        let idSpace = String(repeating: " ", count: idLen)
        var idStr = idSpace
        if let id = id {
            idStr = String((id + idSpace).prefix(lineLen))
        } else {
            let systemUptime = String(format: "%llu", UInt64(ProcessInfo.processInfo.systemUptime * 1000_000))
            idStr = String((systemUptime + idSpace).prefix(lineLen))
        }
        
        // level
        var levelStyle = ""
        switch shared.style {
        case .symble:
            levelStyle = level.symbol
        case .tag:
            levelStyle = level.tag
        }
        let levelStr = "[\(levelStyle)]"
        
        // tag
        var tagStr: String?
        if let tag = tag {
            tagStr = "#\(tag.joined(separator: "."))"
        }
        
        // process
        var processStr = ""
        if let process = process {
            var processStyle = ""
            switch shared.style {
            case .symble:
                processStyle = process.symbol
            case .tag:
                processStyle = process.tag
            }
            processStr = "$\(processStyle)"
        }
        
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
