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
    /// 样式
    public var style: XYLogStyle = .symble
    /// 对齐
    public var align = XYLogAlign()
    
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
        let fileStr = align.format(file: file)
        let funcStr = align.format(function: function)
        let lineStr = align.format(line: line)
        let idStr = align.format(id: id)
        let levelStr = align.format(level: level, style: style)
        let tagStr = align.format(tag: tag)
        let processStr = align.format(process: process, style: style)
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
