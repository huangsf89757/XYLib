//
//  XYLogger.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation
import XYUtil
import CocoaLumberjack

open class XYLogger {
    public init() {
        setup()
    }
    public func setup() {
        DDLog.add(DDOSLogger.sharedInstance)
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        let logDir = (documentDir as NSString).appendingPathComponent("Log")
        let fileManager = XYLoggerFileManager(logsDirectory: logDir)
        let fileLogger = DDFileLogger(logFileManager: fileManager)
        fileLogger.logFormatter = XYLoggerFileFormatter()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.doNotReuseLogFiles = false
        fileLogger.maximumFileSize = 0 // 禁用单文件Size大小限制
        fileLogger.logFileManager.maximumNumberOfLogFiles = 15 // 最多15份日志
        DDLog.add(fileLogger)
        #if DEBUG
        DDLog.add(DDOSLogger.sharedInstance)
        #endif
    }
    public func record(file: String,
                       function: String,
                       line: String,
                       id: String?,
                       level: String,
                       tag: String?,
                       process: String?,
                       content: [Any]) {
//        var message = file + function + line
        var message = file + line // 文件名+行号就已经可以确定代码的位置了
        message += " " + level
        if let id = id {
            message += " " + id
        }
        if let tag = tag {
            message += " " + tag
        }
        if let process = process {
            message += " " + process
        }
        for item in content {
            message += " \(item)"
        }        
        DDLogDebug(message)
    }
}

public final class XYLoggerFileFormatter: NSObject, DDLogFormatter {
    public private(set) var dateFormatter: DateFormatter = .init()
    public init(withFormatter formatter: DateFormatter? = nil) {
        super.init()
        if let formatter = formatter {
            dateFormatter = formatter
        } else {
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        }
    }
    public func format(message logMessage: DDLogMessage) -> String? {
        let timeStr = dateFormatter.string(from: logMessage.timestamp)
        let result = "\(timeStr) \(logMessage.message)"
        return result
    }
}

public final class XYLoggerFileManager: DDLogFileManagerDefault {
    let suffix = ".log"
    public override var newLogFileName: String {
        return XYApp.name + dateFormatter.string(from: Date()) + suffix
    }
    public override func isLogFile(withName fileName: String) -> Bool {
        return fileName.hasPrefix(XYApp.name) && fileName.hasSuffix(suffix)
    }
    
    var _dateFormatter: DateFormatter!
    var dateFormatter: DateFormatter {
        guard _dateFormatter == nil else { return _dateFormatter }
        _dateFormatter = DateFormatter()
        _dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        _dateFormatter.timeZone = .current
        _dateFormatter.dateFormat = "yyyy-MM-dd Z"
        return _dateFormatter
    }
}
