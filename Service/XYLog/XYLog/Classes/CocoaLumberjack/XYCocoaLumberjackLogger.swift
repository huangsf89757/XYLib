//
//  XYCocoaLumberjackLogger.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation
import XYUtil
import CocoaLumberjack

// MARK: - XYCocoaLumberjackLogger
public class XYCocoaLumberjackLogger {
    public static let shared = XYCocoaLumberjackLogger()
    private init() {
        DDLog.add(DDOSLogger.sharedInstance)
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        let logDir = (documentDir as NSString).appendingPathComponent("Log")
        let fileManager = XYCocoaLumberjackFileManager(logsDirectory: logDir)
        let fileLogger = DDFileLogger(logFileManager: fileManager)
        fileLogger.logFormatter = XYCocoaLumberjackFileFormatter()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.doNotReuseLogFiles = false
        fileLogger.maximumFileSize = 0 // 禁用单文件Size大小限制
        fileLogger.logFileManager.maximumNumberOfLogFiles = 15 // 最多15份日志
        DDLog.add(fileLogger)
#if DEBUG
        DDLog.add(DDOSLogger.sharedInstance)
#endif
    }
}

// MARK: - XYLogger
extension XYCocoaLumberjackLogger: XYLogger {
    public func write(data: XYLogData) {
        var message = data.file + data.line
        message += " " + data.level
        message += " " + data.id
        if let tag = data.tag {
            message += " " + tag
        }
        if let interval = data.interval {
            message += " " + interval
        }
        if let process = data.process {
            message += " " + process
        }
        for item in data.content {
            message += " \(item)"
        }
        DDLogDebug(message)
    }
}

// MARK: - XYCocoaLumberjackFileFormatter
public final class XYCocoaLumberjackFileFormatter: NSObject, DDLogFormatter {
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

// MARK: - XYCocoaLumberjackFileManager
public final class XYCocoaLumberjackFileManager: DDLogFileManagerDefault {
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
