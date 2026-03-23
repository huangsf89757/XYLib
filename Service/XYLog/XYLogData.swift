//
//  XYLogData.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogData
public struct XYLogData {
    /// 时间
    public let date = Date()
    /// 文件名
    public let file: String
    /// 函数名
    public let function: String
    /// 行号
    public let line: String
    /// ID
    public let id: String
    /// 级别
    public let level: String
    /// 标签
    public let tag: String?
    /// 进度
    public let process: String?
    /// 内容
    public let content: [Any]
}
