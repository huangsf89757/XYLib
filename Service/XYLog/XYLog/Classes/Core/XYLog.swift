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
    public var aligner = XYLogAligner()
    /// 格式化
    public var formatter = XYLogFormatter()
    
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
    public static func verbose(from: Date? = nil,
                               file: String = #file,
                               function: String = #function,
                               line: Int = #line,
                               id: String? = nil,
                               tag: String? = nil,
                               process: XYLogProcess? = nil,
                               throttle: XYLogThrottle.Method? = nil,
                               aligner: XYLogAligner? = nil,
                               formatter: XYLogFormatter? = nil,
                               content: Any...) {
        shared.record(from: from, file: file, function: function, line: line, id: id, level: .verbose, tag: tag, process: process, throttle: throttle, aligner: aligner, formatter: formatter, content: content)
    }
    
    public static func debug(from: Date? = nil,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             id: String? = nil,
                             tag: String? = nil,
                             process: XYLogProcess? = nil,
                             throttle: XYLogThrottle.Method? = nil,
                             aligner: XYLogAligner? = nil,
                             formatter: XYLogFormatter? = nil,
                             content: Any...) {
        shared.record(from: from, file: file, function: function, line: line, id: id, level: .debug, tag: tag, process: process, throttle: throttle, aligner: aligner, formatter: formatter, content: content)
    }
    
    public static func info(from: Date? = nil,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line,
                            id: String? = nil,
                            tag: String? = nil,
                            process: XYLogProcess? = nil,
                            throttle: XYLogThrottle.Method? = nil,
                            aligner: XYLogAligner? = nil,
                            formatter: XYLogFormatter? = nil,
                            content: Any...) {
        shared.record(from: from, file: file, function: function, line: line, id: id, level: .info, tag: tag, process: process, throttle: throttle, aligner: aligner, formatter: formatter, content: content)
    }
    
    public static func warning(from: Date? = nil,
                               file: String = #file,
                               function: String = #function,
                               line: Int = #line,
                               id: String? = nil,
                               tag: String? = nil,
                               process: XYLogProcess? = nil,
                               throttle: XYLogThrottle.Method? = nil,
                               aligner: XYLogAligner? = nil,
                               formatter: XYLogFormatter? = nil,
                               content: Any...) {
        shared.record(from: from, file: file, function: function, line: line, id: id, level: .warning, tag: tag, process: process, throttle: throttle, aligner: aligner, formatter: formatter, content: content)
    }
    
    public static func error(from: Date? = nil,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             id: String? = nil,
                             tag: String? = nil,
                             process: XYLogProcess? = nil,
                             throttle: XYLogThrottle.Method? = nil,
                             aligner: XYLogAligner? = nil,
                             formatter: XYLogFormatter? = nil,
                             content: Any...) {
        shared.record(from: from, file: file, function: function, line: line, id: id, level: .error, tag: tag, process: process, throttle: throttle, aligner: aligner, formatter: formatter, content: content)
    }
    
    public static func fatal(from: Date? = nil,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             id: String? = nil,
                             tag: String? = nil,
                             process: XYLogProcess? = nil,
                             throttle: XYLogThrottle.Method? = nil,
                             aligner: XYLogAligner? = nil,
                             formatter: XYLogFormatter? = nil,
                             content: Any...) {
        shared.record(from: from, file: file, function: function, line: line, id: id, level: .fatal, tag: tag, process: process, throttle: throttle, aligner: aligner, formatter: formatter, content: content)
    }
}


// MARK: - Record
extension XYLog {
    private func record(from: Date? = nil,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line,
                        id: String? = nil,
                        level: XYLogLevel = .info,
                        tag: String? = nil,
                        process: XYLogProcess? = nil,
                        throttle method: XYLogThrottle.Method? = nil,
                        aligner: XYLogAligner? = nil,
                        formatter: XYLogFormatter? = nil,
                        content: Any...) {
        guard enable else { return }
        guard let logger else { return }
        throttle.check(method: method) { [weak self] in
            guard let self = self else { return }
            guard let data = getData(file: file, function: function, line: line, id: id, level: level, tag: tag, process: process, aligner: aligner, formatter: formatter, content: content) else { return }
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
                         tag: String? = nil,
                         from time: TimeInterval? = nil,
                         process: XYLogProcess? = nil,
                         aligner: XYLogAligner? = nil,
                         formatter: XYLogFormatter? = nil,
                         content: Any...) -> XYLogData? {
        var curAligner = self.aligner
        if let aligner {
            curAligner = aligner
        }
        var curFormatter = self.formatter
        if let formatter {
            curFormatter = formatter
        }
        let fileStr = curAligner.align(file: file)
        let funcStr = curAligner.align(function: function)
        let lineStr = curAligner.align(line: line)
        let idStr = curAligner.align(id: id)
        let levelStr = curFormatter.format(level: level, style: style)
        let tagStr = curFormatter.format(tag: tag)
        let intervalStr = curFormatter.format(interval: time)
        let processStr = curFormatter.format(process: process, style: style)
        let data = XYLogData(file: fileStr,
                             function: funcStr,
                             line: lineStr,
                             id: idStr,
                             level: levelStr,
                             tag: tagStr,
                             interval: intervalStr,
                             process: processStr,
                             content: content)
        return data
    }
}
