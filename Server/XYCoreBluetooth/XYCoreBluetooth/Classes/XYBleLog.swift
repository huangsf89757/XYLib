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
/// 蓝牙日志工具。
///
/// 统一记录与蓝牙交互相关的调试信息，包括调用方、参数与返回值，
/// 便于调试与问题排查。
public final class XYBleLog {
    // MARK: - Properties
    /// 日志标签，用于标识蓝牙相关日志。
    public static let tag = "XY.BLE"
    
    // MARK: - Methods
    /// 记录调试日志。
    ///
    /// 将方法名、参数与返回值格式化后通过 `XYLog` 输出。
    /// - Parameters:
    ///   - file: 源文件路径（默认当前文件）。
    ///   - function: 函数名（默认当前函数）。
    ///   - line: 行号（默认当前行）。
    ///   - id: 可选的关联标识。
    ///   - process: 可选的过程信息。
    ///   - params: 可选的参数字典。
    ///   - returns: 可选的返回值描述。
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
