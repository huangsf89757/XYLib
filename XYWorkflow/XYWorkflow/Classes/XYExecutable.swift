//
//  XYExecutable.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation

// MARK: - XYExecutable
public protocol XYExecutable {
    /// 关联结果类型
    associatedtype ResultType
    /// 唯一标识
    var id: String { get }
    /// 执行状态
    var state: XYState { get }
    /// 超时时间（秒）
    var timeout: TimeInterval { get }
    /// 命令执行时间
    var executeTime: Date? { get }
    /// 执行函数
    func execute() async throws -> ResultType
    /// 取消执行
    func cancel()
}
