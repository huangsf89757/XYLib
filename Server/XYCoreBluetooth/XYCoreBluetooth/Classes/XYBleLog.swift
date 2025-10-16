//
//  XYCentralManagerDelegate.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/10/14.
//

// Module: System
import Foundation
// Module: Basic
import XYExtension
// Module: Server
import XYLog
// Module: Tool
// Module: Business
// Module: Third

// MARK: - XYBleLog
/// 蓝牙日志管理类，提供统一的蓝牙操作日志记录功能
/// 
/// 该类封装了蓝牙相关操作的日志记录，包括参数、返回值等信息，
/// 便于开发过程中调试和问题排查。
public final class XYBleLog {
    // MARK: - Properties
    /// 日志标签，用于标识蓝牙相关的日志
    public static let tag = "XY.BLE"
    
    // MARK: - Methods
    /// 记录调试日志
    ///
    /// 该方法用于记录蓝牙操作的调试信息，包括函数名、参数和返回值等。
    /// 日志格式化后会通过XYLog系统输出，便于开发者追踪蓝牙操作流程。
    ///
    /// - Parameters:
    ///   - file: 源文件路径，默认为当前文件
    ///   - function: 函数名，默认为当前函数
    ///   - line: 行号，默认为当前行
    ///   - id: 可选的标识符，用于关联相关操作
    ///   - process: 可选的处理进程信息
    ///   - params: 可选的参数字典，记录函数输入参数
    ///   - returns: 可选的返回值描述
    public static func debug(file: String = #file,
                       function: String = #function,
                       line: Int = #line,
                       id: String? = nil,
                       process: XYLogProcess? = nil,
                       params: [String: String]? = nil,
                       returns: String? = nil) {
        var content_params = "void"
        if let params {
            content_params = "\n" + params.map { (key, value) in
                "   - \(key) = \(value)"
            }.joined(separator: "\n")
        }
        var content_returns = "void"
        if let returns {
            content_returns = "\n" + "  > \(returns)"
        }
        let content = """
            
            func \(function)
            params: \(content_params)
            return: \(content_returns)
            """
        XYLog.debug(file: file,
                    function: function,
                    line: line,
                    id: id,
                    tag: [tag],
                    process: process,
                    content: content)
    }
}
