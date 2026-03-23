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
    private var style: XYLogStyle = .symble
    /// 节流
    private lazy var throttle: XYLogThrottle = { return XYLogThrottle() }()
    /// 队列
    private let logQueue = DispatchQueue(label: "com.xy.log.writer", qos: .utility)
    
    // MARK: func
    public static func config(enable: Bool = true, style: XYLogStyle = .tag, logger: XYLogger) {
        shared.enable = enable
        shared.style = style
        shared.logger = logger
    }
}

// MARK: - Func
extension XYLog {
    public static func verbose(file: String = #file,
                               function: String = #function,
                               line: Int = #line,
                               id: String? = nil,
                               tag: XYLogTag? = nil,
                               process: XYLogProcess? = nil,
                               content: Any...) {
        shared.record(file: file, function: function, line: line, id: id, level: .verbose, tag: tag, process: process, content: content)
    }
    
    public static func debug(file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             id: String? = nil,
                             tag: XYLogTag? = nil,
                             process: XYLogProcess? = nil,
                             content: Any...) {
        shared.record(file: file, function: function, line: line, id: id, level: .debug, tag: tag, process: process, content: content)
    }
    
    public static func info(file: String = #file,
                            function: String = #function,
                            line: Int = #line,
                            id: String? = nil,
                            tag: XYLogTag? = nil,
                            process: XYLogProcess? = nil,
                            content: Any...) {
        shared.record(file: file, function: function, line: line, id: id, level: .info, tag: tag, process: process, content: content)
    }
    
    public static func warning(file: String = #file,
                               function: String = #function,
                               line: Int = #line,
                               id: String? = nil,
                               tag: XYLogTag? = nil,
                               process: XYLogProcess? = nil,
                               content: Any...) {
        shared.record(file: file, function: function, line: line, id: id, level: .warning, tag: tag, process: process, content: content)
    }
    
    public static func error(file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             id: String? = nil,
                             tag: XYLogTag? = nil,
                             process: XYLogProcess? = nil,
                             content: Any...) {
        shared.record(file: file, function: function, line: line, id: id, level: .error, tag: tag, process: process, content: content)
    }
    
    public static func fatal(file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             id: String? = nil,
                             tag: XYLogTag? = nil,
                             process: XYLogProcess? = nil,
                             content: Any...) {
        shared.record(file: file, function: function, line: line, id: id, level: .fatal, tag: tag, process: process, content: content)
    }
}


// MARK: - Record
extension XYLog {
    private func record(file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        id: String?,
                        level: XYLogLevel,
                        tag: XYLogTag?,
                        process: XYLogProcess?,
                        content: Any...) {
        guard enable else { return }
        guard let logger else { return }
        throttle.check(tag: tag) { [weak self] in
            guard let self = self else { return }
            guard let data = getData(file: file, function: function, line: line, id: id, level: level, tag: tag, process: process, content: content) else { return }
            self.logQueue.async {
                logger.write(data: data)
            }
        }
    }
    
    private func getData(file: String = #file,
                         function: String = #function,
                         line: Int = #line,
                         id: String?,
                         level: XYLogLevel,
                         tag: XYLogTag?,
                         process: XYLogProcess?,
                         content: Any...) -> XYLogData? {
        let fileStr = format(file: file)
        let funcStr = format(function: function)
        let lineStr = format(line: line)
        let idStr = format(id: id)
        let levelStr = format(level: level)
        let tagStr = format(tag: tag)
        let processStr = format(process: process)
        let data = XYLogData(file: fileStr,
                             function: funcStr,
                             line: lineStr,
                             id: idStr,
                             level: levelStr,
                             tag: tagStr,
                             process: processStr,
                             content: content)
        return data
    }
}

// MARK: - Format
extension XYLog {
    private func format(file: String) -> String {
        let len = 25
        let space = String(repeating: " ", count: len)
        let name = ((file as NSString).lastPathComponent as NSString).deletingPathExtension
        let str = String((name + space).prefix(len))
        return str
    }
    
    private func format(function: String) -> String {
        let len = 30
        let space = String(repeating: " ", count: len)
        let str = String((function + space).prefix(len))
        return str
    }
    
    private func format(line: Int) -> String {
        let len = 4
        let space = String(repeating: " ", count: len)
        let str = String(("\(line)" + space).prefix(len))
        return str
    }
    
    private func format(id: String?) -> String {
        let len = 8
        let space = String(repeating: " ", count: len)
        var str = space
        if let id = id {
            str = String((id + space).prefix(len))
        } else {
            let systemUptime = String(format: "%llu", UInt64(ProcessInfo.processInfo.systemUptime * 1000_000))
            str = String((systemUptime + space).prefix(len))
        }
        return str
    }
    
    private func format(level: XYLogLevel) -> String {
        var styleStr = ""
        switch style {
        case .symble:
            styleStr = level.symbol
        case .tag:
            styleStr = level.tag
        }
        return "[\(styleStr)]"
    }
    
    private func format(tag: XYLogTag?) -> String? {
        var str: String?
        if let tag = tag {
            switch tag {
            case .com(let contents):
                str = "#\(contents.joined(separator: "."))"
            case .tag(contents: let contents, throttle: let interval):
                str = "#\(contents.joined(separator: "."))"
            }
        }
        return str
    }
    
    private func format(process: XYLogProcess?) -> String? {
        var str: String?
        if let process = process {
            var processStr = ""
            switch style {
            case .symble:
                processStr = process.symbol
            case .tag:
                processStr = process.tag
            }
            str = "$\(processStr)"
        }
        return str
    }
}
